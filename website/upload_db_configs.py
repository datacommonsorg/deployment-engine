import server.lib.config as lib_config
from server.routes.admin_panel.utils import upload_db_configs


if __name__ == '__main__':
  cfg = lib_config.get_config()
  upload_db_configs(cfg)
