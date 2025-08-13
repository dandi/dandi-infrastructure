import {
  to = module.api_sandbox.module.heroku.heroku_formation.heroku_web
  id = "dandi-api-staging:web"
}

import {
  to = module.api_sandbox.module.heroku.heroku_formation.heroku_worker
  id = "dandi-api-staging:worker"
}

import {
  to = heroku_formation.api_staging_checksum_worker
  id = "dandi-api-staging:checksum-worker"
}
