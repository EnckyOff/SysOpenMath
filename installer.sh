#!/usr/bin/env bash

JULIA_LTS=1.6.7
JULIA_LATEST=1.9
JULIA_OLD=""
SKIP_CONFIRM=0
#JULIA_SCRIPT_URL= $(curl )
function usage() {
  echo " Справка по installer.sh

Скрипт устанавливает Julia. По умолчанию ставится последняя стабильная версия ($JULIA_LATEST-latest).

Options and arguments:
  -h, --help               : Показать справку
  --lts                    : Установить LTS версию ($JULIA_LTS)
  --l                      : Получить список доступных для установки версий
  --ver                     : Указать версию для установки

  Директория в которую будет загружен и распакован архив .tar.gz:
    По умолчанию /opt/julias при запуске с правами суперпользователя или $HOME/packages/julias при запуске без них .
  Директория в которую будет установлена символьная ссылка на julia.
    По умолчанию при запуске с правами суперпользователя /usr/local/bin, иначе $HOME/.local/bin .
"
}

#function install_jq(){
#}


function get_list_releases() {
  echo "Список доступных версий для установки:"
  versions=$(curl -s "https://api.github.com/repos/julialang/julia/tags"| jq -r '.[] | .name')
  for i in "${versions[@]}"
  do
  echo "$i"
  done
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
      if ! command -v jq --version &> /dev/null
      then
        echo "флаг --v требует установленного jg."
        exit 1
      fi
      get_list_releases
      shift
      exit 0
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
  if [[ ! $REPLY =~ ^[Yy] ]]; then
     echo "Запускаю установку пакетов"
    # exit 1
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
    # if [[ "$julia --version" > /dev/null]]; then
    confirm
    exec julia installer.jl
fi

unameOut="$(uname -s)"
case "${unameOut}" in
    Linux*) install_julia_linux ;;
    *)
        echo "Unsupported platform $(unameOut)" >&2
        exit 1
        ;;
esac
