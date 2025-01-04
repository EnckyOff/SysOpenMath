#!/usr/bin/env bash

JULIA_LTS=1.10.7
JULIA_LATEST=1.11.2
JULIA_OLD=""
JQ_INSTALL=1
JUPYTER_INSTALLED=1
JULIA_DOCS_URL="https://github.com/EnckyOff/JuliaInstaller/blob/master/JuliaRussianGuide.pdf"
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
USE_PIPX=1

function check_python_version() {
  if [[ "$(printf '%s\n' "3.11" "$PYTHON_VERSION" | sort -V | head -n 1)" == "3.11" ]]; then
    USE_PIPX=0
  fi
}


function usage() {
  echo " Справка по installer.sh

Скрипт устанавливает Julia. По умолчанию ставится последняя стабильная версия ($JULIA_LATEST).


Options and arguments:
  -h, --help               : Показать справку
  --lts                    : Установить LTS версию ($JULIA_LTS)
  --l                      : Получить список доступных для установки версий
  --ver                    : Указать версию для установки

  Директория в которую будет загружен и распакован архив .tar.gz:
    По умолчанию /opt/julias
  Директория в которую будет установлена символьная ссылка на julia.
    По умолчанию при запуске /usr/local/bin.
"
}

function install_jq() {
sudo apt install jq
}

function check_jq() {
  if command -v jq &>/dev/null; then
  JQ_INSTALL=0
  fi
}

function delete_jq() {
  if [[ "$JQ_INSTALL" -eq 1 ]]; then
  echo "Удаляем jq"
  sudo apt remove jq
  fi
}

function package_installer() {
  if [ "$(which julia)" == "0" ] &> /dev/null; then
   bash julia package_installer.jl
  fi
}

function check_jupyter_install() {
    check_python_version
    command -v jupyter &>/dev/null && JUPYTER_INSTALLED=0
}

function jupyter_install() {
  if [[ "$JUPYTER_INSTALLED" -eq 1 ]]; then
      echo "Установка jupyter"y
      if [[ "$USE_PIPX" -eq 0 ]]; then
        pipx install notebook > /dev/null 2>&1
      else 
       python3 -m pip install notebook > /dev/null 2>&1
      fi
  fi 
}

function scilab_kernel_installation(){
    read -p "Хотите установить Scilab в Jupyter? (y/n): "
    if [[ "$REPLY" =~ ^[Yy]$ ]]; then
      pipx inject notebook scilab_kernel
    fi
    }

function add_pipx_to_PATH(){
  echo "Настраиваем пути Jupyter Notebook"
  pipx_venv_path=$(sudo pipx environment | grep "PIPX_BIN_DIR" | cut -d "=" -f 2)
  echo "# Created by SystemOpenMath" >> ~/.bashrc
  echo "export PATH=\"\$PATH:$notebook_venv_path\"" >> ~/.bashrc
}


function get_list_releases() {
  echo "Список доступных версий для установки:"
  versions=$(curl -s "https://api.github.com/repos/julialang/julia/tags"| jq -r '.[] | .name')
  for i in "${versions[@]}"
  do
  echo "$i"
  done
}

if [[ "$(whoami)" == "root" ]]; then
  JULIA_DOWNLOAD="${JULIA_DOWNLOAD:-"/opt/julias"}"
  JULIA_INSTALL="${JULIA_INSTALL:-"/usr/local/bin"}"
else
  echo "необходим root!"
  exit 1
fi




function welcome() {
  if   command -v julia &>/dev/null; then
    echo "Julia уже установлена"
  else
    echo "Скрипт:"
    echo ""
    echo "  - попытается загрузить Julia $version"
    echo "  - Создаст символьную ссылку julia"
    echo "  - Установит Jupyter Notebook"
    echo ""
    echo "Путь для загрузки Julia: ${JULIA_DOWNLOAD@Q}"
    echo "Путь для символьной ссылки Julia: ${JULIA_INSTALL@Q}"
    echo ""
    if ! [ -d "$JULIA_DOWNLOAD" ]; then
      echo "Директория для скачивания автоматически создастся"
    fi
    
    if ! [  -w "$JULIA_INSTALL" ]; then
      echo "Недостаточно прав для установки в ${JULIA_INSTALL@Q}."
      exit 1
    fi
  fi
}


function confirm_julia() {
  read -p "Вы согласны установить Julia? (Y/N) " -n 1 -r
  echo
  if [[  $REPLY =~ ^[Yy] ]]; then
     install_julia
  fi
}



function get_url_from_platform_arch_version() {
  platform=$1
  arch=$2
  version=$3
  [[ $arch == *"64" ]] && bit=64 || bit=32
  [[ $arch == "mac"* ]] && suffix=mac64.dmg || suffix="$platform-$arch.tar.gz"
  minor=$(echo "$version" | cut -d. -f1-2 | cut -d- -f1)
  url="https://julialang-s3.julialang.org/bin/$platform/x$bit/$minor/julia-$version-$suffix"
  echo "$url"
}

function install_julia() {
  mkdir -p "$JULIA_DOWNLOAD"
  cd "$JULIA_DOWNLOAD" || exit 1
  arch=$(uname -m)

  # Download specific version
  LATEST=0
  if [ -n "${JULIA_VERSION+set}" ]; then
    version="$JULIA_VERSION"
  else
    LATEST=1
    version="$JULIA_LATEST"
  fi
  echo "Загрузка Julia  $version, пожалуйста, подождите"
  if [ ! -f "julia-$version.tar.gz" ]; then
    url="$(get_url_from_platform_arch_version linux "$arch" "$version")"
    if ! $WGET -c "$url" -O "julia-$version.tar.gz"; then
      echo "ошибка загрузки julia-$version"
      rm "julia-$version.tar.gz"
      return
    fi
  else
    echo "уже загружено"
  fi
  if [ ! -d "julia-$version" ]; then
  echo "Распаковка архива с julia"
    mkdir -p "julia-$version"
    tar zxf "julia-$version.tar.gz" -C "julia-$version" --strip-components 1
  fi
  if [[ "$LATEST" == "1" ]]; then
    JLVERSION=$(./julia-$version/bin/julia -version | cut -d' ' -f3)
    if [ -d "julia-$JLVERSION" ]; then
      echo "Внимание: Последняя версия $JLVERSION уже установлена."
      rm -rf "julia-$version.tar.gz" "julia-$version"
    else
      mv "julia-$version.tar.gz" "julia-$JLVERSION.tar.gz"
      mv "julia-$version" "julia-$JLVERSION"
    fi
    version="$JLVERSION"
  fi

  major=${version:0:3}
  rm -f "$JULIA_INSTALL"/julia{,-"$major",-"$version"}
  julia="$PWD/julia-$version/bin/julia"

  echo "создание символьной ссылки"
  # create symlink
  ln -s "$julia" "$JULIA_INSTALL/julia"
  ln -s "$julia" "$JULIA_INSTALL/julia-$major"
  ln -s "$julia" "$JULIA_INSTALL/julia-$version"
}

start_install(){
welcome
check_jupyter_install
confirm_julia
jupyter_install
scilab_kernel_installation
package_installer
}


while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -h|--help)
      usage
      shift
      exit 0
      ;;
    --lts)
      JULIA_VERSION="$JULIA_LTS"
      shift 
      ;;
      --ver)
      JULIA_VERSION="$2"
      shift 2
      ;;
    -l| --list)
      check_jq
      if [[ "$JQ_INSTALL" -ne 0 ]]; then
        echo "флаг --l требует установленного jg."
        read -p "установить jq? (Y/N) "
        if [[  $REPLY =~ ^[Yy] ]]; then
          install_jq
          fi
      else
        get_list_releases
      fi
      shift
      exit 1
      ;;
    *)    # unknown
      echo "Неизвестный флаг: $1" >&2
      usage
      exit 1;
      ;;
esac
done

# --------------------------------------------------------

start_install