{ pkgs, python, ... }:
with builtins;
with pkgs.lib;
let
  pypi_fetcher_src = builtins.fetchTarball {
    name = "nix-pypi-fetcher";
    url = "https://github.com/DavHau/nix-pypi-fetcher/tarball/e105186d0101ead100a64e86b1cd62abd1482e62";
    # Hash obtained using `nix-prefetch-url --unpack <url>`
    sha256 = "0nyil3npbqhwgqmxp65s3zn0hgisx14sjyv70ibbbdimfzwvy5qv";
  };
  pypiFetcher = import pypi_fetcher_src { inherit pkgs; };
  fetchPypi = pypiFetcher.fetchPypi;
  fetchPypiWheel = pypiFetcher.fetchPypiWheel;
  is_py_module = pkg:
    isAttrs pkg && hasAttr "pythonModule" pkg;
  normalizeName = name: (replaceStrings ["_"] ["-"] (toLower name));
  replace_deps = oldAttrs: inputs_type: self:
    map (pypkg:
      let
        pname = normalizeName (get_pname pypkg);
      in
        if self ? "${pname}" && pypkg != self."${pname}" then
          trace "Updated inherited nixpkgs dep ${pname} from ${pypkg.version} to ${self."${pname}".version}"
          self."${pname}"
        else
          pypkg
    ) (oldAttrs."${inputs_type}" or []);
  override = pkg:
    if hasAttr "overridePythonAttrs" pkg then
        pkg.overridePythonAttrs
    else
        pkg.overrideAttrs;
  nameMap = {
    pytorch = "torch";
  };
  get_pname = pkg:
    let
      res = tryEval (
        if pkg ? src.pname then
          pkg.src.pname
        else if pkg ? pname then
          let pname = pkg.pname; in
            if nameMap ? "${pname}" then nameMap."${pname}" else pname
          else ""
      );
    in
      toString res.value;
  get_passthru = pypi_name: nix_name:
    # if pypi_name is in nixpkgs, we must pick it, otherwise risk infinite recursion.
    let
      python_pkgs = python.pkgs;
      pname = if hasAttr "${pypi_name}" python_pkgs then pypi_name else nix_name;
    in
      if hasAttr "${pname}" python_pkgs then 
        let result = (tryEval 
          (if isNull python_pkgs."${pname}" then
            {}
          else
            python_pkgs."${pname}".passthru)); 
        in
          if result.success then result.value else {}
      else {};
  tests_on_off = enabled: pySelf: pySuper:
    let
      mod = {
        doCheck = enabled;
        doInstallCheck = enabled;
      };
    in
    {
      buildPythonPackage = args: pySuper.buildPythonPackage ( args // {
        doCheck = enabled;
        doInstallCheck = enabled;
      } );
      buildPythonApplication = args: pySuper.buildPythonPackage ( args // {
        doCheck = enabled;
        doInstallCheck = enabled;
      } );
    };
  pname_passthru_override = pySelf: pySuper: {
    fetchPypi = args: (pySuper.fetchPypi args).overrideAttrs (oa: {
      passthru = { inherit (args) pname; };
    });
  };
  mergeOverrides = with pkgs.lib; foldl composeExtensions (self: super: {});
  merge_with_overr = enabled: overr:
    mergeOverrides [(tests_on_off enabled) pname_passthru_override overr];
  select_pkgs = ps: [
    ps."alembic"
    ps."altair"
    ps."celery"
    ps."cryptography"
    ps."datasketch"
    ps."elasticsearch"
    ps."flask"
    ps."flask-bcrypt"
    ps."flask-login"
    ps."flask-migrate"
    ps."flask-restful"
    ps."flask-script"
    ps."flask-sqlalchemy"
    ps."flask-wtf"
    ps."google-auth"
    ps."google-auth-oauthlib"
    ps."gunicorn"
    ps."markdown"
    ps."networkx"
    ps."numpy"
    ps."oauthlib"
    ps."pandas"
    ps."psycopg2-binary"
    ps."pyjwt"
    ps."python-dateutil"
    ps."pyyaml"
    ps."redis"
    ps."requests"
    ps."sigmatools"
    ps."six"
    ps."sqlalchemy"
    ps."tabulate"
    ps."werkzeug"
    ps."wtforms"
    ps."xlrd"
  ];
  overrides = manylinux1: autoPatchelfHook: merge_with_overr false (python-self: python-super: let self = {
    "alembic" = python-self.buildPythonPackage {
      pname = "alembic";
      version = "1.4.3";
      src = fetchPypiWheel "alembic" "1.4.3" "alembic-1.4.3-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "alembic" "alembic") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ mako python-dateutil python-editor sqlalchemy ];
    };
    "altair" = python-self.buildPythonPackage {
      pname = "altair";
      version = "4.1.0";
      src = fetchPypiWheel "altair" "4.1.0" "altair-4.1.0-py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "altair" "altair") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ entrypoints jinja2 jsonschema numpy pandas toolz ];
    };
    "amqp" = python-self.buildPythonPackage {
      pname = "amqp";
      version = "5.0.1";
      src = fetchPypiWheel "amqp" "5.0.1" "amqp-5.0.1-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "amqp" "amqp") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ vine ];
    };
    "aniso8601" = python-self.buildPythonPackage {
      pname = "aniso8601";
      version = "8.0.0";
      src = fetchPypiWheel "aniso8601" "8.0.0" "aniso8601-8.0.0-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "aniso8601" "aniso8601") // { provider = "wheel"; };
    };
    "attrs" = python-self.buildPythonPackage {
      pname = "attrs";
      version = "20.2.0";
      src = fetchPypiWheel "attrs" "20.2.0" "attrs-20.2.0-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "attrs" "attrs") // { provider = "wheel"; };
    };
    "bcrypt" = override python-super.bcrypt ( oldAttrs: {
      pname = "bcrypt";
      version = "3.2.0";
      passthru = (get_passthru "bcrypt" "bcrypt") // { provider = "sdist"; };
      buildInputs = with python-self; (replace_deps oldAttrs "buildInputs" self) ++ [ cffi ];
      propagatedBuildInputs = with python-self; (replace_deps oldAttrs "propagatedBuildInputs" self) ++ [ cffi six ];
      src = fetchPypi "bcrypt" "3.2.0";
    });
    "billiard" = python-self.buildPythonPackage {
      pname = "billiard";
      version = "3.6.3.0";
      src = fetchPypiWheel "billiard" "3.6.3.0" "billiard-3.6.3.0-py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "billiard" "billiard") // { provider = "wheel"; };
    };
    "cachetools" = python-self.buildPythonPackage {
      pname = "cachetools";
      version = "4.1.1";
      src = fetchPypiWheel "cachetools" "4.1.1" "cachetools-4.1.1-py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "cachetools" "cachetools") // { provider = "wheel"; };
    };
    "celery" = python-self.buildPythonPackage {
      pname = "celery";
      version = "5.0.1";
      src = fetchPypiWheel "celery" "5.0.1" "celery-5.0.1-py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "celery" "celery") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ billiard click click-didyoumean click-repl kombu pytz vine ];
    };
    "certifi" = python-self.buildPythonPackage {
      pname = "certifi";
      version = "2020.6.20";
      src = fetchPypiWheel "certifi" "2020.6.20" "certifi-2020.6.20-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "certifi" "certifi") // { provider = "wheel"; };
    };
    "cffi" = python-self.buildPythonPackage {
      pname = "cffi";
      version = "1.14.3";
      src = fetchPypiWheel "cffi" "1.14.3" "cffi-1.14.3-cp37-cp37m-manylinux1_x86_64.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "cffi" "cffi") // { provider = "wheel"; };
      nativeBuildInputs = [ autoPatchelfHook ];
      autoPatchelfIgnoreMissingDeps = true;
      propagatedBuildInputs = with python-self; manylinux1 ++ [ pycparser ];
    };
    "chardet" = python-self.buildPythonPackage {
      pname = "chardet";
      version = "3.0.4";
      src = fetchPypiWheel "chardet" "3.0.4" "chardet-3.0.4-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "chardet" "chardet") // { provider = "wheel"; };
    };
    "click" = python-self.buildPythonPackage {
      pname = "click";
      version = "7.1.2";
      src = fetchPypiWheel "click" "7.1.2" "click-7.1.2-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "click" "click") // { provider = "wheel"; };
    };
    "click-didyoumean" = override python-super.click-didyoumean ( oldAttrs: {
      pname = "click-didyoumean";
      version = "0.0.3";
      passthru = (get_passthru "click-didyoumean" "click-didyoumean") // { provider = "sdist"; };
      buildInputs = with python-self; (replace_deps oldAttrs "buildInputs" self) ++ [  ];
      propagatedBuildInputs = with python-self; (replace_deps oldAttrs "propagatedBuildInputs" self) ++ [ click ];
      src = fetchPypi "click-didyoumean" "0.0.3";
    });
    "click-repl" = python-self.buildPythonPackage {
      pname = "click-repl";
      version = "0.1.6";
      src = fetchPypiWheel "click-repl" "0.1.6" "click_repl-0.1.6-py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "click-repl" "click-repl") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ click prompt-toolkit six ];
    };
    "cryptography" = override python-super.cryptography ( oldAttrs: {
      pname = "cryptography";
      version = "3.1.1";
      passthru = (get_passthru "cryptography" "cryptography") // { provider = "sdist"; };
      buildInputs = with python-self; (replace_deps oldAttrs "buildInputs" self) ++ [ cffi ];
      propagatedBuildInputs = with python-self; (replace_deps oldAttrs "propagatedBuildInputs" self) ++ [ cffi six ];
      src = fetchPypi "cryptography" "3.1.1";
    });
    "datasketch" = python-self.buildPythonPackage {
      pname = "datasketch";
      version = "1.5.1";
      src = fetchPypiWheel "datasketch" "1.5.1" "datasketch-1.5.1-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "datasketch" "datasketch") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ numpy ];
    };
    "decorator" = python-self.buildPythonPackage {
      pname = "decorator";
      version = "4.4.2";
      src = fetchPypiWheel "decorator" "4.4.2" "decorator-4.4.2-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "decorator" "decorator") // { provider = "wheel"; };
    };
    "deprecated" = python-self.buildPythonPackage {
      pname = "deprecated";
      version = "1.2.10";
      src = fetchPypiWheel "deprecated" "1.2.10" "Deprecated-1.2.10-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "deprecated" "deprecated") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ wrapt ];
    };
    "elasticsearch" = python-self.buildPythonPackage {
      pname = "elasticsearch";
      version = "7.9.1";
      src = fetchPypiWheel "elasticsearch" "7.9.1" "elasticsearch-7.9.1-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "elasticsearch" "elasticsearch") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ certifi urllib3 ];
    };
    "entrypoints" = python-self.buildPythonPackage {
      pname = "entrypoints";
      version = "0.3";
      src = fetchPypiWheel "entrypoints" "0.3" "entrypoints-0.3-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "entrypoints" "entrypoints") // { provider = "wheel"; };
    };
    "flask" = python-self.buildPythonPackage {
      pname = "flask";
      version = "1.1.2";
      src = fetchPypiWheel "flask" "1.1.2" "Flask-1.1.2-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "flask" "flask") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ click itsdangerous jinja2 werkzeug ];
    };
    "flask-bcrypt" = override python-super.flask-bcrypt ( oldAttrs: {
      pname = "flask-bcrypt";
      version = "0.7.1";
      passthru = (get_passthru "flask-bcrypt" "flask-bcrypt") // { provider = "sdist"; };
      buildInputs = with python-self; (replace_deps oldAttrs "buildInputs" self) ++ [  ];
      propagatedBuildInputs = with python-self; (replace_deps oldAttrs "propagatedBuildInputs" self) ++ [ bcrypt flask ];
      src = fetchPypi "flask-bcrypt" "0.7.1";
    });
    "flask-login" = python-self.buildPythonPackage {
      pname = "flask-login";
      version = "0.5.0";
      src = fetchPypiWheel "flask-login" "0.5.0" "Flask_Login-0.5.0-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "flask-login" "flask_login") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ flask ];
    };
    "flask-migrate" = python-self.buildPythonPackage {
      pname = "flask-migrate";
      version = "2.5.3";
      src = fetchPypiWheel "flask-migrate" "2.5.3" "Flask_Migrate-2.5.3-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "flask-migrate" "flask_migrate") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ alembic flask flask-sqlalchemy ];
    };
    "flask-restful" = python-self.buildPythonPackage {
      pname = "flask-restful";
      version = "0.3.8";
      src = fetchPypiWheel "flask-restful" "0.3.8" "Flask_RESTful-0.3.8-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "flask-restful" "flask-restful") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ aniso8601 flask pytz six ];
    };
    "flask-script" = override python-super.flask_script ( oldAttrs: {
      pname = "flask-script";
      version = "2.0.6";
      passthru = (get_passthru "flask-script" "flask_script") // { provider = "sdist"; };
      buildInputs = with python-self; (replace_deps oldAttrs "buildInputs" self) ++ [  ];
      propagatedBuildInputs = with python-self; (replace_deps oldAttrs "propagatedBuildInputs" self) ++ [ flask ];
      src = fetchPypi "flask-script" "2.0.6";
    });
    "flask-sqlalchemy" = python-self.buildPythonPackage {
      pname = "flask-sqlalchemy";
      version = "2.4.4";
      src = fetchPypiWheel "flask-sqlalchemy" "2.4.4" "Flask_SQLAlchemy-2.4.4-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "flask-sqlalchemy" "flask_sqlalchemy") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ flask sqlalchemy ];
    };
    "flask-wtf" = python-self.buildPythonPackage {
      pname = "flask-wtf";
      version = "0.14.3";
      src = fetchPypiWheel "flask-wtf" "0.14.3" "Flask_WTF-0.14.3-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "flask-wtf" "flask_wtf") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ flask itsdangerous wtforms ];
    };
    "google-auth" = python-self.buildPythonPackage {
      pname = "google-auth";
      version = "1.22.1";
      src = fetchPypiWheel "google-auth" "1.22.1" "google_auth-1.22.1-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "google-auth" "google_auth") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ cachetools pyasn1-modules rsa setuptools six ];
    };
    "google-auth-oauthlib" = python-self.buildPythonPackage {
      pname = "google-auth-oauthlib";
      version = "0.4.1";
      src = fetchPypiWheel "google-auth-oauthlib" "0.4.1" "google_auth_oauthlib-0.4.1-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "google-auth-oauthlib" "google-auth-oauthlib") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ google-auth requests-oauthlib ];
    };
    "gunicorn" = python-self.buildPythonPackage {
      pname = "gunicorn";
      version = "20.0.4";
      src = fetchPypiWheel "gunicorn" "20.0.4" "gunicorn-20.0.4-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "gunicorn" "gunicorn") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ setuptools ];
    };
    "idna" = python-self.buildPythonPackage {
      pname = "idna";
      version = "2.10";
      src = fetchPypiWheel "idna" "2.10" "idna-2.10-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "idna" "idna") // { provider = "wheel"; };
    };
    "importlib-metadata" = python-self.buildPythonPackage {
      pname = "importlib-metadata";
      version = "2.0.0";
      src = fetchPypiWheel "importlib-metadata" "2.0.0" "importlib_metadata-2.0.0-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "importlib-metadata" "importlib-metadata") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ zipp ];
    };
    "itsdangerous" = python-self.buildPythonPackage {
      pname = "itsdangerous";
      version = "1.1.0";
      src = fetchPypiWheel "itsdangerous" "1.1.0" "itsdangerous-1.1.0-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "itsdangerous" "itsdangerous") // { provider = "wheel"; };
    };
    "jinja2" = python-self.buildPythonPackage {
      pname = "jinja2";
      version = "2.11.2";
      src = fetchPypiWheel "jinja2" "2.11.2" "Jinja2-2.11.2-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "jinja2" "jinja2") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ markupsafe ];
    };
    "jsonschema" = python-self.buildPythonPackage {
      pname = "jsonschema";
      version = "3.2.0";
      src = fetchPypiWheel "jsonschema" "3.2.0" "jsonschema-3.2.0-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "jsonschema" "jsonschema") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ attrs importlib-metadata pyrsistent setuptools six ];
    };
    "kombu" = python-self.buildPythonPackage {
      pname = "kombu";
      version = "5.0.2";
      src = fetchPypiWheel "kombu" "5.0.2" "kombu-5.0.2-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "kombu" "kombu") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ amqp importlib-metadata ];
    };
    "mako" = python-self.buildPythonPackage {
      pname = "mako";
      version = "1.1.3";
      src = fetchPypiWheel "mako" "1.1.3" "Mako-1.1.3-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "mako" "Mako") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ markupsafe ];
    };
    "markdown" = python-self.buildPythonPackage {
      pname = "markdown";
      version = "3.3.2";
      src = fetchPypiWheel "markdown" "3.3.2" "Markdown-3.3.2-py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "markdown" "markdown") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ importlib-metadata ];
    };
    "markupsafe" = python-self.buildPythonPackage {
      pname = "markupsafe";
      version = "1.1.1";
      src = fetchPypiWheel "markupsafe" "1.1.1" "MarkupSafe-1.1.1-cp37-cp37m-manylinux1_x86_64.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "markupsafe" "markupsafe") // { provider = "wheel"; };
      nativeBuildInputs = [ autoPatchelfHook ];
      autoPatchelfIgnoreMissingDeps = true;
      propagatedBuildInputs = with python-self; manylinux1 ++ [  ];
    };
    "networkx" = python-self.buildPythonPackage {
      pname = "networkx";
      version = "2.5";
      src = fetchPypiWheel "networkx" "2.5" "networkx-2.5-py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "networkx" "networkx") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ decorator ];
    };
    "numpy" = python-self.buildPythonPackage {
      pname = "numpy";
      version = "1.19.2";
      src = fetchPypiWheel "numpy" "1.19.2" "numpy-1.19.2-cp37-cp37m-manylinux2010_x86_64.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "numpy" "numpy") // { provider = "wheel"; };
      nativeBuildInputs = [ autoPatchelfHook ];
      autoPatchelfIgnoreMissingDeps = true;
      propagatedBuildInputs = with python-self; manylinux1 ++ [  ];
    };
    "oauthlib" = python-self.buildPythonPackage {
      pname = "oauthlib";
      version = "3.1.0";
      src = fetchPypiWheel "oauthlib" "3.1.0" "oauthlib-3.1.0-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "oauthlib" "oauthlib") // { provider = "wheel"; };
    };
    "pandas" = python-self.buildPythonPackage {
      pname = "pandas";
      version = "1.1.3";
      src = fetchPypiWheel "pandas" "1.1.3" "pandas-1.1.3-cp37-cp37m-manylinux1_x86_64.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "pandas" "pandas") // { provider = "wheel"; };
      nativeBuildInputs = [ autoPatchelfHook ];
      autoPatchelfIgnoreMissingDeps = true;
      propagatedBuildInputs = with python-self; manylinux1 ++ [ numpy python-dateutil pytz ];
    };
    "progressbar2" = python-self.buildPythonPackage {
      pname = "progressbar2";
      version = "3.53.1";
      src = fetchPypiWheel "progressbar2" "3.53.1" "progressbar2-3.53.1-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "progressbar2" "progressbar2") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ python-utils six ];
    };
    "prompt-toolkit" = python-self.buildPythonPackage {
      pname = "prompt-toolkit";
      version = "3.0.8";
      src = fetchPypiWheel "prompt-toolkit" "3.0.8" "prompt_toolkit-3.0.8-py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "prompt-toolkit" "prompt_toolkit") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ wcwidth ];
    };
    "psycopg2-binary" = python-self.buildPythonPackage {
      pname = "psycopg2-binary";
      version = "2.8.6";
      src = fetchPypiWheel "psycopg2-binary" "2.8.6" "psycopg2_binary-2.8.6-cp37-cp37m-manylinux1_x86_64.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "psycopg2-binary" "psycopg2-binary") // { provider = "wheel"; };
      nativeBuildInputs = [ autoPatchelfHook ];
      autoPatchelfIgnoreMissingDeps = true;
      propagatedBuildInputs = with python-self; manylinux1 ++ [  ];
    };
    "pyasn1" = python-self.buildPythonPackage {
      pname = "pyasn1";
      version = "0.4.8";
      src = fetchPypiWheel "pyasn1" "0.4.8" "pyasn1-0.4.8-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "pyasn1" "pyasn1") // { provider = "wheel"; };
    };
    "pyasn1-modules" = python-self.buildPythonPackage {
      pname = "pyasn1-modules";
      version = "0.2.8";
      src = fetchPypiWheel "pyasn1-modules" "0.2.8" "pyasn1_modules-0.2.8-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "pyasn1-modules" "pyasn1-modules") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ pyasn1 ];
    };
    "pycparser" = python-self.buildPythonPackage {
      pname = "pycparser";
      version = "2.20";
      src = fetchPypiWheel "pycparser" "2.20" "pycparser-2.20-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "pycparser" "pycparser") // { provider = "wheel"; };
    };
    "pyjwt" = python-self.buildPythonPackage {
      pname = "pyjwt";
      version = "1.7.1";
      src = fetchPypiWheel "pyjwt" "1.7.1" "PyJWT-1.7.1-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "pyjwt" "pyjwt") // { provider = "wheel"; };
    };
    "pymisp" = python-self.buildPythonPackage {
      pname = "pymisp";
      version = "2.4.133";
      src = fetchPypiWheel "pymisp" "2.4.133" "pymisp-2.4.133-py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "pymisp" "pymisp") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ deprecated jsonschema python-dateutil requests ];
    };
    "pyrsistent" = override python-super.pyrsistent ( oldAttrs: {
      pname = "pyrsistent";
      version = "0.17.3";
      passthru = (get_passthru "pyrsistent" "pyrsistent") // { provider = "sdist"; };
      buildInputs = with python-self; (replace_deps oldAttrs "buildInputs" self) ++ [  ];
      propagatedBuildInputs = with python-self; (replace_deps oldAttrs "propagatedBuildInputs" self) ++ [  ];
      src = fetchPypi "pyrsistent" "0.17.3";
    });
    "python-dateutil" = python-self.buildPythonPackage {
      pname = "python-dateutil";
      version = "2.8.1";
      src = fetchPypiWheel "python-dateutil" "2.8.1" "python_dateutil-2.8.1-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "python-dateutil" "python-dateutil") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ six ];
    };
    "python-editor" = python-self.buildPythonPackage {
      pname = "python-editor";
      version = "1.0.4";
      src = fetchPypiWheel "python-editor" "1.0.4" "python_editor-1.0.4-py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "python-editor" "python-editor") // { provider = "wheel"; };
    };
    "python-utils" = python-self.buildPythonPackage {
      pname = "python-utils";
      version = "2.4.0";
      src = fetchPypiWheel "python-utils" "2.4.0" "python_utils-2.4.0-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "python-utils" "python-utils") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ six ];
    };
    "pytz" = python-self.buildPythonPackage {
      pname = "pytz";
      version = "2020.1";
      src = fetchPypiWheel "pytz" "2020.1" "pytz-2020.1-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "pytz" "pytz") // { provider = "wheel"; };
    };
    "pyyaml" = override python-super.pyyaml ( oldAttrs: {
      pname = "pyyaml";
      version = "5.3.1";
      passthru = (get_passthru "pyyaml" "pyyaml") // { provider = "sdist"; };
      buildInputs = with python-self; (replace_deps oldAttrs "buildInputs" self) ++ [  ];
      propagatedBuildInputs = with python-self; (replace_deps oldAttrs "propagatedBuildInputs" self) ++ [  ];
      src = fetchPypi "pyyaml" "5.3.1";
    });
    "redis" = python-self.buildPythonPackage {
      pname = "redis";
      version = "3.5.3";
      src = fetchPypiWheel "redis" "3.5.3" "redis-3.5.3-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "redis" "redis") // { provider = "wheel"; };
    };
    "requests" = python-self.buildPythonPackage {
      pname = "requests";
      version = "2.24.0";
      src = fetchPypiWheel "requests" "2.24.0" "requests-2.24.0-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "requests" "requests") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ certifi chardet idna urllib3 ];
    };
    "requests-oauthlib" = python-self.buildPythonPackage {
      pname = "requests-oauthlib";
      version = "1.3.0";
      src = fetchPypiWheel "requests-oauthlib" "1.3.0" "requests_oauthlib-1.3.0-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "requests-oauthlib" "requests_oauthlib") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ oauthlib requests ];
    };
    "rsa" = python-self.buildPythonPackage {
      pname = "rsa";
      version = "4.6";
      src = fetchPypiWheel "rsa" "4.6" "rsa-4.6-py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "rsa" "rsa") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ pyasn1 ];
    };
    "setuptools" = override python-super.setuptools ( oldAttrs: {
      pname = "setuptools";
      version = "47.3.1";
      passthru = (get_passthru "setuptools" "setuptools") // { provider = "nixpkgs"; };
      buildInputs = with python-self; (replace_deps oldAttrs "buildInputs" self) ++ [  ];
      propagatedBuildInputs = with python-self; (replace_deps oldAttrs "propagatedBuildInputs" self) ++ [  ];
    });
    "sigmatools" = python-self.buildPythonPackage {
      pname = "sigmatools";
      version = "0.18.1";
      src = fetchPypiWheel "sigmatools" "0.18.1" "sigmatools-0.18.1-py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "sigmatools" "sigmatools") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ progressbar2 pymisp pyyaml ];
    };
    "six" = python-self.buildPythonPackage {
      pname = "six";
      version = "1.15.0";
      src = fetchPypiWheel "six" "1.15.0" "six-1.15.0-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "six" "six") // { provider = "wheel"; };
    };
    "sqlalchemy" = python-self.buildPythonPackage {
      pname = "sqlalchemy";
      version = "1.3.20";
      src = fetchPypiWheel "sqlalchemy" "1.3.20" "SQLAlchemy-1.3.20-cp37-cp37m-manylinux2010_x86_64.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "sqlalchemy" "sqlalchemy") // { provider = "wheel"; };
      nativeBuildInputs = [ autoPatchelfHook ];
      autoPatchelfIgnoreMissingDeps = true;
      propagatedBuildInputs = with python-self; manylinux1 ++ [  ];
    };
    "tabulate" = python-self.buildPythonPackage {
      pname = "tabulate";
      version = "0.8.7";
      src = fetchPypiWheel "tabulate" "0.8.7" "tabulate-0.8.7-py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "tabulate" "tabulate") // { provider = "wheel"; };
    };
    "toolz" = python-self.buildPythonPackage {
      pname = "toolz";
      version = "0.11.1";
      src = fetchPypiWheel "toolz" "0.11.1" "toolz-0.11.1-py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "toolz" "toolz") // { provider = "wheel"; };
    };
    "urllib3" = python-self.buildPythonPackage {
      pname = "urllib3";
      version = "1.25.11";
      src = fetchPypiWheel "urllib3" "1.25.11" "urllib3-1.25.11-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "urllib3" "urllib3") // { provider = "wheel"; };
    };
    "vine" = python-self.buildPythonPackage {
      pname = "vine";
      version = "5.0.0";
      src = fetchPypiWheel "vine" "5.0.0" "vine-5.0.0-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "vine" "vine") // { provider = "wheel"; };
    };
    "wcwidth" = python-self.buildPythonPackage {
      pname = "wcwidth";
      version = "0.2.5";
      src = fetchPypiWheel "wcwidth" "0.2.5" "wcwidth-0.2.5-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "wcwidth" "wcwidth") // { provider = "wheel"; };
    };
    "werkzeug" = python-self.buildPythonPackage {
      pname = "werkzeug";
      version = "1.0.1";
      src = fetchPypiWheel "werkzeug" "1.0.1" "Werkzeug-1.0.1-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "werkzeug" "werkzeug") // { provider = "wheel"; };
    };
    "wrapt" = override python-super.wrapt ( oldAttrs: {
      pname = "wrapt";
      version = "1.12.1";
      passthru = (get_passthru "wrapt" "wrapt") // { provider = "sdist"; };
      buildInputs = with python-self; (replace_deps oldAttrs "buildInputs" self) ++ [  ];
      propagatedBuildInputs = with python-self; (replace_deps oldAttrs "propagatedBuildInputs" self) ++ [  ];
      src = fetchPypi "wrapt" "1.12.1";
    });
    "wtforms" = python-self.buildPythonPackage {
      pname = "wtforms";
      version = "2.3.3";
      src = fetchPypiWheel "wtforms" "2.3.3" "WTForms-2.3.3-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "wtforms" "wtforms") // { provider = "wheel"; };
      propagatedBuildInputs = with python-self; [ markupsafe ];
    };
    "xlrd" = python-self.buildPythonPackage {
      pname = "xlrd";
      version = "1.2.0";
      src = fetchPypiWheel "xlrd" "1.2.0" "xlrd-1.2.0-py2.py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "xlrd" "xlrd") // { provider = "wheel"; };
    };
    "zipp" = python-self.buildPythonPackage {
      pname = "zipp";
      version = "3.3.1";
      src = fetchPypiWheel "zipp" "3.3.1" "zipp-3.3.1-py3-none-any.whl";
      format = "wheel";
      dontStrip = true;
      passthru = (get_passthru "zipp" "zipp") // { provider = "wheel"; };
    };
  }; in self);
in
{ inherit overrides select_pkgs; }
