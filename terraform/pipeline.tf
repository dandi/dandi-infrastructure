resource "heroku_pipeline" "dandi_pipeline" {
  name = "dandi-pipeline"

  owner {
    id   = data.heroku_team.dandi.id
    type = "team"
  }
}

resource "heroku_pipeline_coupling" "staging" {
  app_id   = module.api_sandbox_heroku.app_id
  pipeline = heroku_pipeline.dandi_pipeline.id
  stage    = "staging"
}

resource "heroku_pipeline_coupling" "production" {
  app_id   = module.api_heroku.app_id
  pipeline = heroku_pipeline.dandi_pipeline.id
  stage    = "production"
}
