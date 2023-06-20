#!/usr/bin/env bash

JULIA_LTS=1.6.7
JULIA_LATEST=1.9
JULIA_OLD=""
SKIP_CONFIRM=0
JQ_INSTALLED=1
JULIA_DOCS_URL=https://github.com/EnckyOff/JuliaInstaller/blob/master/JuliaRussianGuide.pdf
function usage() {
  echo " Справка по installer.sh

Скрипт устанавливает Julia. По умолчанию ставится последняя стабильная версия ($JULIA_LATEST-latest).

Options and arguments:
  -h, --help               : Показать справку
  --lts                    : Установить LTS версию ($JULIA_LTS)
  --l                      : Получить список доступных для установки версий
  --ver                    : Указать версию для установки

  Директория в которую будет загружен и распакован архив .tar.gz:
    По умолчанию /opt/julias при запуске с правами суперпользователя или $HOME/packages/julias при запуске без них.
  Директория в которую будет установлена символьная ссылка на julia.
    По умолчанию при запуске с правами суперпользователя /usr/local/bin, иначе $HOME/.local/bin.
"
}

function install_jq(){
sudo apt install jq
}

function delete_jq(){
  if [[ "$JQ_INSTALLED" -eq 0 ]]; then
  echo "Удаляем jq"
  sudo apt remove jq
  fi
}

function package_installer(){
  exec julia installer.jl
}

function jupyter_install() { # посмотреть можно ли собирать jupyter из исходников
if ! [[ -x "$(command -v jupyter notebook --ver)" ]]; then
    echo "устанавливаем Jupyter"
    pip install notebook
fi
}

function docs_link_to_desktop(){ # Написать исправить баг с рабочим столом русскогоязычного пользователя
read -p "Создать ссылку на документацию на рабочем столе? (Y/N) " -n 1 -r
   echo
   if [[  $REPLY =~ ^[Yy] ]]; then
    wget -q $JULIA_DOCS_URL
    path=$(command pwd)
    ln -s $path/JuliaRussianGuide.pdf /home/$USER/Desktop
    fi
    return
}


function get_list_releases() {
  echo "Список доступных версий для установки:"
  versions=$(curl -s "https://api.github.com/repos/julialang/julia/tags"| jq -r '.[] | .name')
  for i in "${versions[@]}"
  do
  echo "$i"
  done
  return
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
      shift
      shift
      ;;
    --l)
      if ! [ -x "$(command -v jq --version)" ]
      then
        echo "флаг --l требует установленного jg."
        echo
        read -p "установить? При завершении установки jq будет удален (Y/N) " -n 1 -r
        if [[  $REPLY =~ ^[Yy] ]]; then
          install_jq
          JQ_INSTALLED=0
          fi
      else
        JQ_INSTALLED=1
        get_list_releases
        echo
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

if [[ "$(whoami)" == "root" ]]; then
  JULIA_DOWNLOAD="${JULIA_DOWNLOAD:-"/opt/julias"}"
  JULIA_INSTALL="${JULIA_INSTALL:-"/usr/local/bin"}"
else
  JULIA_DOWNLOAD="${JULIA_DOWNLOAD:-"$HOME/packages/julias"}"
  JULIA_INSTALL="${JULIA_INSTALL:-"$HOME/.local/bin"}"
fi
WGET="wget --retry-connrefused -t 3 -q"

function header() {
 echo "Инсталлятор installer.sh"
}



function welcome() {
  usage
  header
  mkdir -p "$JULIA_INSTALL" # не создаст папку если отказались
  LATEST=0
  if [ -n "${JULIA_VERSION+set}" ]; then
    version="$JULIA_VERSION"
  else
    LATEST=1
    version="$JULIA_LATEST-latest"
  fi
  echo "Скрипт:"
  echo ""
  echo "  - попытается загрузить Julia '$version'"
  echo "  - Создаст символьную ссылку julia"
  echo "  - Создаст символьную ссылку julia-VER"
  echo ""
  echo "Путь для загрузки: ${JULIA_DOWNLOAD@Q}"
  echo "Путь для символьной ссылки: ${JULIA_INSTALL@Q}"
  echo ""
  if [ ! -d "$JULIA_DOWNLOAD" ]; then
    echo "Директория для скачивания автоматически создастся"
  fi
  if [ ! -w "$JULIA_INSTALL" ]; then
    echo "Недостаточно прав для установки в ${JULIA_INSTALL@Q}."
    exit 1
  fi
}



function confirm() {
  read -p "Вы согласны? (Y/N) " -n 1 -r
  echo
  if [[  $REPLY =~ ^[Yy] ]]; then
     install_julia_linux
    else
    exit 1
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

function install_julia_linux() {
  mkdir -p "$JULIA_DOWNLOAD"
  cd "$JULIA_DOWNLOAD" || exit 1
  arch=$(uname -m)

  # Download specific version
  LATEST=0
  if [ -n "${JULIA_VERSION+set}" ]; then
    version="$JULIA_VERSION"
  else
    LATEST=1
    version="$JULIA_LATEST-latest"
  fi
  echo "Загрузка Julia  $version, пожалуйста подождите"
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

  if [[ "$UPGRADE_CONFIRM" == "1" ]]; then
    old_major="${JULIA_OLD:0:3}"
    if [ "$USER" == "root" ] && [ -n "$SUDO_USER" ]; then
      JULIAENV="/home/$SUDO_USER"
    else
      JULIAENV=$HOME
    fi
    JULIAENV="${JULIAENV}/.julia/environments"
    echo "Copying environments in ${JULIAENV} from v${old_major} to v${major}"
    cp -rp "${JULIAENV}/v${old_major}" "${JULIAENV}/v${major}"
  fi
  echo "создание символьной ссылки"
  # create symlink
  ln -s "$julia" "$JULIA_INSTALL/julia"
  ln -s "$julia" "$JULIA_INSTALL/julia-$major"
  ln -s "$julia" "$JULIA_INSTALL/julia-$version"
}


# --------------------------------------------------------

welcome
if [[ "$SKIP_CONFIRM" == "0" ]]; then
    if  [[ -x "$(command -v julia --version)" ]]; then
    echo "Julia уже установлена"
    else
      confirm
    fi
fi

unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*) jupyter_install
            delete_jq
            package_installer
            ;;
    *)
        echo "Unsupported platform $(unameOut)" >&2
        exit 1
        ;;
esac
