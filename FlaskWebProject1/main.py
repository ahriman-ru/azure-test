# -*- coding: utf-8 -*-
# старт flask-приложения
import os
import sys
import datetime
from app import app, db
from flask import make_response, jsonify
from flask_migrate import Migrate, migrate, upgrade, init
import models

migrations = Migrate(app, db)

# Выполняется если миграции еще не применены к данному проекту (самый первый раз),
if not os.path.exists('migrations'):
    with app.app_context():
        init()  # Создается папка migrations
        migrate()  # Создается определение первой версии бд по описанию в models.py
        upgrade()  # Выполняется скрипт миграции


# Upgrade базы дянных до последней версии
@app.route("/upgrade_bd", methods=['GET'])
def upgrade_bd():
    upgrade()
    return "success", 200


@app.route("/", methods=['GET'])
def index():
    return "Time: {}, Version: {}".format(datetime.datetime.now().strftime("%Y-%m-%d %H:%M:%S"), os.environ.get('CURRENT_VERSION_ID', ""))


@app.route("/db/version", methods=['GET'])
def bd_version():
    ver = db.engine.execute("SELECT version_num FROM alembic_version LIMIT 1;").first()
    return jsonify({'version': ver[0]}), 200


from service_bot import service
from lk_bot import lk

app.register_blueprint(service, url_prefix='/service')
app.register_blueprint(lk, url_prefix='/lk')


env_serv = os.getenv('SERVER_SOFTWARE')
