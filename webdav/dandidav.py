from __future__ import annotations
from collections.abc import Iterator
from dataclasses import dataclass
import io
from operator import attrgetter
from typing import IO
from cheroot import wsgi
from dandi.dandiapi import DandiAPIClient, RemoteAsset, RemoteDandiset
from dandi.exceptions import NotFoundError
from ruamel.yaml import YAML
from wsgidav.dav_provider import DAVCollection, DAVNonCollection, DAVProvider
from wsgidav.util import join_uri
from wsgidav.wsgidav_app import WsgiDAVApp


class DandiProvider(DAVProvider):
    def __init__(self, instance: str = "dandi", token: str | None = None) -> None:
        super().__init__()
        self.client = DandiAPIClient.for_dandi_instance(instance, token=token)

    def get_resource_inst(self, path: str, environ: dict) -> RootCollection:
        return RootCollection("/", environ).resolve("/", path)

    def is_readonly(self) -> bool:
        return True


class RootCollection(DAVCollection):
    def get_member_names(self) -> list[str]:
        return ["dandisets"]

    def get_member(self, name: str) -> DandisetCollection | None:
        if name == "dandisets":
            return DandisetCollection(join_uri(self.path, name), self.environ)
        else:
            return None

    def is_link(self) -> bool:
        # Fix for <https://github.com/mar10/wsgidav/issues/301>
        return False


class DandisetCollection(DAVCollection):
    """Collection of Dandisets in instance"""

    def __init__(self, path: str, environ: dict) -> None:
        super().__init__(path, environ)
        self.client: DandiAPIClient = self.provider.client

    def get_member_list(self) -> list[DandisetResource]:
        return [
            DandisetResource(join_uri(self.path, d.identifier), self.environ, d)
            for d in self.client.get_dandisets()
        ]

    def get_member_names(self) -> list[str]:
        return [d.identifier for d in self.client.get_dandisets()]

    def get_member(self, name: str) -> DandisetResource | None:
        try:
            d = self.client.get_dandiset(name, lazy=False)
        except NotFoundError:
            return None
        else:
            return DandisetResource(join_uri(self.path, name), self.environ, d)

    def is_link(self) -> bool:
        # Fix for <https://github.com/mar10/wsgidav/issues/301>
        return False


class DandisetResource(DAVCollection):
    def __init__(self, path: str, environ: dict, dandiset: RemoteDandiset) -> None:
        super().__init__(path, environ)
        self.dandiset = dandiset

    def get_display_info(self) -> dict[str, str]:
        return {"type": "Dandiset"}

    def get_member_names(self) -> list[str]:
        names = ["draft"]
        if self.dandiset.most_recent_published_version is not None:
            names.append("latest")
            names.append("releases")
        return names

    def get_member(self, name: str) -> VersionResource | ReleasesCollection:
        if name == "draft":
            d = self.dandiset.for_version(self.dandiset.draft_version)
            return VersionResource(join_uri(self.path, name), self.environ, d)
        elif (
            name == "latest"
            and (v := self.dandiset.most_recent_published_version) is not None
        ):
            d = self.dandiset.for_version(v)
            return VersionResource(join_uri(self.path, name), self.environ, d)
        elif (
            name == "releases"
            and self.dandiset.most_recent_published_version is not None
        ):
            return ReleasesCollection(
                join_uri(self.path, name), self.environ, self.dandiset
            )
        else:
            return None

    def is_link(self) -> bool:
        # Fix for <https://github.com/mar10/wsgidav/issues/301>
        return False

    def get_creation_date(self) -> float:
        return self.dandiset.created.timestamp()

    def get_last_modified(self) -> float:
        return self.dandiset.modified.timestamp()


class ReleasesCollection(DAVCollection):
    def __init__(self, path: str, environ: dict, dandiset: RemoteDandiset) -> None:
        super().__init__(path, environ)
        self.dandiset = dandiset

    def get_display_info(self) -> dict[str, str]:
        return {"type": "Dandiset releases"}

    def get_member_list(self) -> list[VersionResource]:
        return [
            VersionResource(
                join_uri(self.path, v.identifier),
                self.environ,
                self.dandiset.for_version(v),
            )
            for v in self.dandiset.get_versions()
            if v.identifier != "draft"
        ]

    def get_member_names(self) -> list[str]:
        return [
            v.identifier
            for v in self.dandiset.get_versions()
            if v.identifier != "draft"
        ]

    def get_member(self, name: str) -> VersionResource | None:
        if name == "draft":
            return None
        try:
            d = self.dandiset.for_version(name)
        except NotFoundError:
            return None
        else:
            return VersionResource(join_uri(self.path, name), self.environ, d)

    def is_link(self) -> bool:
        # Fix for <https://github.com/mar10/wsgidav/issues/301>
        return False


class AssetFolder(DAVCollection):
    def __init__(
        self, path: str, environ: dict, dandiset: RemoteDandiset, asset_path_prefix: str
    ) -> None:
        super().__init__(path, environ)
        self.dandiset = dandiset
        self.asset_path_prefix = asset_path_prefix

    def get_member_list(self) -> list[AssetResource | AssetFolder]:
        members = []
        for n in self.iter_dandi_folder():
            if isinstance(n, DandiAssetFolder):
                members.append(
                    AssetFolder(
                        join_uri(self.path, n.name),
                        self.environ,
                        self.dandiset,
                        n.prefix,
                    )
                )
            else:
                assert isinstance(n, DandiAsset)
                asset = self.dandiset.get_asset(n.asset_id)
                members.append(
                    AssetResource(join_uri(self.path, n.name), self.environ, asset)
                )
        return members

    def get_member_names(self) -> list[str]:
        return [n.name for n in self.iter_dandi_folder()]

    def get_member(self, name: str) -> AssetResource | AssetFolder | None:
        if self.asset_path_prefix == "":
            prefix = name
        else:
            prefix = f"{self.asset_path_prefix}/{name}"
        for a in self.dandiset.get_assets_with_path_prefix(prefix, order="path"):
            if a.path == prefix:
                return AssetResource(join_uri(self.path, name), self.environ, a)
            elif a.path.startswith(f"{prefix}/"):
                return AssetFolder(
                    join_uri(self.path, name),
                    self.environ,
                    self.dandiset,
                    prefix,
                )
        return None

    def is_link(self) -> bool:
        # Fix for <https://github.com/mar10/wsgidav/issues/301>
        return False

    def iter_dandi_folder(self) -> Iterator[DandiAssetFolder | DandiAsset]:
        path = (
            f"/dandisets/{self.dandiset.identifier}/versions"
            f"/{self.dandiset.version.identifier}/assets/paths"
        )
        for node in self.dandiset.client.paginate(
            path, params={"path_prefix": self.asset_path_prefix}
        ):
            if self.asset_path_prefix == "":
                name = node["path"]
            else:
                name = node["path"].removeprefix(f"{self.asset_path_prefix}/")
            if node["asset"] is not None:
                yield DandiAsset(name, asset_id=node["asset"]["asset_id"])
            else:
                yield DandiAssetFolder(name, prefix=node["path"])


@dataclass
class DandiAsset:
    name: str
    asset_id: str


@dataclass
class DandiAssetFolder:
    name: str
    prefix: str


class AssetResource(DAVNonCollection):
    def __init__(self, path: str, environ: dict, asset: RemoteAsset) -> None:
        super().__init__(path, environ)
        self.asset = asset

    def get_content(self) -> IO[bytes]:
        return self.asset.as_readable().open()

    def get_content_length(self) -> int:
        return self.asset.size

    def get_content_type(self) -> str:
        try:
            return self.asset.get_raw_metadata()["encodingFormat"]
        except KeyError:
            return "application/octet-stream"

    def get_display_info(self) -> dict:
        return {"type": "Asset"}

    def is_link(self) -> bool:
        # Fix for <https://github.com/mar10/wsgidav/issues/301>
        return False

    def get_etag(self) -> str | None:
        try:
            return self.asset.get_raw_digest()
        except NotFoundError:
            return None

    def support_etag(self) -> bool:
        return True

    def get_creation_date(self) -> float:
        return self.asset.created.timestamp()

    def get_last_modified(self) -> float:
        return self.asset.modified.timestamp()


class VersionResource(AssetFolder):
    """
    A Dandiset at a specific version, containing top-level assets and asset
    folders
    """

    def __init__(self, path: str, environ: dict, dandiset: RemoteDandiset) -> None:
        super().__init__(path, environ, dandiset, "")

    def get_display_info(self) -> dict[str, str]:
        return {"type": "Dandiset version"}

    def get_member_list(self) -> list[AssetResource | AssetFolder | DandisetYaml]:
        members = super().get_member_list()
        members.append(
            DandisetYaml(
                join_uri(self.path, "dandiset.yaml"),
                self.environ,
                self.dandiset.get_raw_metadata(),
            )
        )
        members.sort(key=attrgetter("name"))
        return members

    def get_member_names(self) -> list[str]:
        names = super().get_member_names()
        names.append("dandiset.yaml")
        names.sort()
        return names

    def get_member(
        self, name: str
    ) -> AssetResource | AssetFolder | DandisetYaml | None:
        if name == "dandiset.yaml":
            return DandisetYaml(
                join_uri(self.path, "dandiset.yaml"),
                self.environ,
                self.dandiset.get_raw_metadata(),
            )
        else:
            return super().get_member(name)

    def is_link(self) -> bool:
        # Fix for <https://github.com/mar10/wsgidav/issues/301>
        return False

    def get_creation_date(self) -> float:
        return self.dandiset.version.timestamp()

    def get_last_modified(self) -> float:
        return self.dandiset.version.modified.timestamp()


class DandisetYaml(DAVNonCollection):
    def __init__(self, path: str, environ: dict, metadata: dict) -> None:
        super().__init__(path, environ)
        self.metadata = metadata

    def get_content(self) -> IO[bytes]:
        yaml = YAML(typ="safe")
        yaml.default_flow_style = False
        out = io.BytesIO()
        yaml.dump(self.metadata, out)
        out.seek(0)
        return out

    def get_content_length(self) -> None:
        return None

    def get_content_type(self) -> str:
        return "application/yaml"

    def get_display_info(self) -> dict:
        return {"type": "Dandiset metadata"}

    def is_link(self) -> bool:
        # Fix for <https://github.com/mar10/wsgidav/issues/301>
        return False

    def get_etag(self) -> None:
        return None

    def support_etag(self) -> bool:
        return False


if __name__ == "__main__":
    config = {
        "host": "127.0.0.1",
        "port": 8080,
        "provider_mapping": {
            "/": DandiProvider(),
        },
        "simple_dc": {
            "user_mapping": {
                "/": True,
            },
        },
        "verbose": 4,
    }
    app = WsgiDAVApp(config)
    server = wsgi.Server(
        bind_addr=(config["host"], config["port"]),
        wsgi_app=app,
    )
    try:
        server.start()
    except KeyboardInterrupt:
        print("Received Ctrl-C: stopping...")
    finally:
        server.stop()
