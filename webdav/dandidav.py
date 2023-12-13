from __future__ import annotations
from datetime import datetime
from typing import IO
from cheroot import wsgi
from dandi.dandiapi import DandiAPIClient, RemoteAsset, RemoteDandiset
from dandi.exceptions import NotFoundError
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
    """A Dandiset viewed as a collection of Dandiset versions"""

    def __init__(self, path: str, environ: dict, dandiset: RemoteDandiset) -> None:
        super().__init__(path, environ)
        self.dandiset = dandiset

    def get_display_info(self) -> dict[str, str]:
        return {"type": "Dandiset"}

    def get_member_list(self) -> list[VersionResource]:
        return [
            VersionResource(
                join_uri(self.path, v.identifier),
                self.environ,
                self.dandiset.for_version(v),
            )
            for v in self.dandiset.get_versions()
        ]

    def get_member_names(self) -> list[str]:
        return [v.identifier for v in self.dandiset.get_versions()]

    def get_member(self, name: str) -> VersionResource | None:
        try:
            d = self.dandiset.for_version(name)
        except NotFoundError:
            return None
        else:
            return VersionResource(join_uri(self.path, name), self.environ, d)

    def is_link(self) -> bool:
        # Fix for <https://github.com/mar10/wsgidav/issues/301>
        return False

    def get_creation_date(self) -> float:
        return self.dandiset.created.timestamp()

    def get_last_modified(self) -> float:
        return self.dandiset.modified.timestamp()


class VersionResource(DAVCollection):
    """A Dandiset at a specific version, containing assets"""

    def __init__(self, path: str, environ: dict, dandiset: RemoteDandiset) -> None:
        super().__init__(path, environ)
        self.dandiset = dandiset

    def get_display_info(self) -> dict[str, str]:
        return {"type": "Dandiset version"}

    def get_member_list(self) -> list[AssetResource]:
        return [
            AssetResource(join_uri(self.path, a.identifier), self.environ, a)
            for a in self.dandiset.get_assets()
        ]

    def get_member_names(self) -> list[str]:
        return [a.identifier for a in self.dandiset.get_assets()]

    def get_member(self, name: str) -> AssetResource | None:
        try:
            a = self.dandiset.get_asset(name)
        except NotFoundError:
            return None
        else:
            return AssetResource(join_uri(self.path, name), self.environ, a)

    def is_link(self) -> bool:
        # Fix for <https://github.com/mar10/wsgidav/issues/301>
        return False

    def get_creation_date(self) -> float:
        return self.dandiset.version.timestamp()

    def get_last_modified(self) -> float:
        return self.dandiset.version.modified.timestamp()


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

    def get_display_name(self) -> str:
        return self.asset.path

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
