#!/usr/bin/env bash
set -e 
JULIA_LTS=1.10.10
JULIA_LATEST=1.11.7
JULIA_OLD=""
JQ_INSTALL=1
JUPYTER_INSTALLED=0
PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
USE_PIPX=0


function check_python_version() {
  if [[ "$(printf '%s\n' "3.11" "$PYTHON_VERSION" | sort -V | tail -n 1)" == "$PYTHON_VERSION" ]]; then
    USE_PIPX=1
    install_pipx
  fi
}


function usage() {
  echo " Справка по installer.sh

Скрипт устанавливает Julia. По умолчанию ставится последняя стабильная версия ($JULIA_LATEST).


Options and arguments:
  -h, --help               : Показать справку
  --lts                    : Установить LTS версию ($JULIA_LTS)
  -l                      : Получить список доступных для установки версий
  --ver                    : Указать версию для установки

  Директория в которую будет загружен и распакован архив .tar.gz:
    По умолчанию home/user/julias
  Директория в которую будет установлена символьная ссылка на julia.
    По умолчанию при запуске home/user/.local/bin.
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
    USE_PIPX=$USE_PIPX julia package_installer.jl 2>/dev/null || {
        echo "Ошибка: Не удалось запустить package_installer.jl"
        return 1
    }
}

  function check_jupyter_install() {
      check_python_version
      if command -v jupyter &>/dev/null; then
        JUPYTER_INSTALLED=1
    else
        JUPYTER_INSTALLED=0
    fi
  }
function install_pipx(){
  echo "Установка pipx"
  sudo apt install pipx
  pipx ensurepath
  source ~/.bashrc
}

function jupyter_install() {
  if [[ "$JUPYTER_INSTALLED" -eq 0 ]]; then
      echo "Установка jupyter"
      if [[ "$USE_PIPX" -eq 1 ]]; then
      pipx install --include-deps jupyter
      else 
       python3 -m pip install notebook jupyter-lab
      fi
  fi 
}

function scilab_kernel_install(){
    read -rp "Хотите установить Scilab kernel в Jupyter? (y/n): " reply
    if [[ "$reply" =~ ^[YyДд]$ ]]; then
      apt install scilab
      pipx inject --include-apps --include-deps jupyter scilab_kernel
      PIPX_PATH="$(pipx environment | grep PIPX_LOCAL_VENVS | cut -d= -f2)"
      source "$PIPX_PATH"/jupyter/bin/activate
      # python3 -m scilab_kernel.check
      python3 -m scilab_kernel install --user
      deactivate 
      echo "Ядро scilab успешно добавлено в Jupyter!" 
      return 0
    fi
    }
function bash_kernel_install(){
    read -rp "Хотите установить bash kernel в Jupyter? (y/n): " reply   
     if [[ "$reply" =~ ^[YyДд]$ ]]; then
      pipx inject --include-apps --include-deps jupyter bash_kernel
      PIPX_PATH="$(pipx environment | grep PIPX_LOCAL_VENVS | cut -d= -f2)"
      source "$PIPX_PATH"/jupyter/bin/activate
      #python3 -m bash_kernel check
      python3 -m bash_kernel.install --user
      deactivate 
      echo "Ядро Bash успешно добавлено в Jupyter!" 
      return 0
    fi
}

function octave_kernel_install(){
    read -rp "Хотите установить octave kernel в Jupyter? (y/n): " reply   
     if [[ "$reply" =~ ^[Yy]$ ]]; then
      apt install octave
      pipx inject --include-apps --include-deps jupyter octave_kernel
      PIPX_PATH="$(pipx environment | grep PIPX_LOCAL_VENVS | cut -d= -f2)"
      source "$PIPX_PATH"/jupyter/bin/activate
      #python3 -m bash_kernel check
      python3 -m octave_kernel install --user
      deactivate
      echo "Ядро Octave успешно добавлено в Jupyter!" 
      return 0
    fi
}
function wolfram_engine_install(){
  url="https://account.wolfram.com/dl/WolframEngine?version=14.2.1&platform=Linux"
  git_url="https://github.com/WolframResearch/WolframLanguageForJupyter.git"
  read -rp "Хотите установить wolfram kernel в Jupyter? (y/n): " reply   
  if [[ "$reply" =~ ^[Yy]$ ]]; then
    apt install git -y
    echo "Проверка наличия установленного Wolfram Mathematica или Engine..."
    if command -v Mathematica &> /dev/null || command -v wolframscript &> /dev/null; then
      mkdir -p .wolfram_installation_temp
      cd .wolfram_installation_temp || exit
      echo "Загрузка WolframKernelForJupyter"
      git clone "$git_url" .
      echo "Регистрация ядра Wolfram в Jupyter"
      ./configure-jupyter.wls add
      echo "Ядро Wolfram успешно добавлено в Jupyter!"
      return 0
    fi
    echo "Wolfram не найден начинается установка Wolfram Engine"
    read -r -p "Введите свой wolfram ID: " wolfram_id
    read -r -p "Введите пароль: " wolfram_password
    echo
    mkdir -p .wolfram_installation_temp
    cd .wolfram_installation_temp || exit
    wget -O install_engine.sh "$url"
    chmod +x install_engine.sh
    sudo ./install_engine.sh
    local script_path
    script_path=$(sudo find /usr/local/Wolfram -type f -name wolframscript | head -n1)
    if [[ -n "$script_path" ]]; then
      sudo ln -sf "$script_path" /usr/local/bin/wolframscript
    else
      echo "Не найден wolframscript для создания ссылки."
    fi
    if command -v wolframscript &> /dev/null; then
      echo "Активация Wolfram Engine..."
      wolframscript -username "$wolfram_id" -password "$wolfram_password"
      echo "wolfram активирован!"
      rm installer_engine.sh
      echo "Загрузка WolframKernelForJupyter..."
      git clone "$git_url" .
      echo "Регистрация ядра Wolfram в Jupyter ..."
      ./configure-jupyter.wls add
      # rm -rf .wolfram_installation_temp/
      echo "Установка wolfram завершена!"
    else
      echo "Не удалось найти wolframscript после установки. Проверьте установку вручную."
      return 1
    fi
    return 0
  else 
    return 0
  fi
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
      shift 2
      ;;
    -l| --list)
      check_jq
      if [[ "$JQ_INSTALL" -ne 0 ]]; then
        echo "флаг --l требует установленного jg."
        read -pr "установить jq? (Y/N) "
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

if [[ "$(whoami)" == "root" ]]; then
  JULIA_DOWNLOAD="${JULIA_DOWNLOAD:-"/opt/julias"}"
  JULIA_INSTALL="${JULIA_INSTALL:-"/usr/local/bin"}"
else
  JULIA_DOWNLOAD="${JULIA_DOWNLOAD:-"$HOME/packages/julias"}"
  JULIA_INSTALL="${JULIA_INSTALL:-"$HOME/.local/bin"}"
fi
WGET="wget --retry-connrefused -t 3"

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
    version="$JULIA_LATEST"
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



function confirm_julia() {
  read -p "Вы согласны установить Julia? (Y/N) " -n 1 -r
  echo
  if [[  $REPLY =~ ^[YyДд] ]]; then
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
  echo "Загрузка Julia  $version, пожалуйста подождите"
  if [ ! -f "julia-$version.tar.gz" ]; then
    url="$(get_url_from_platform_arch_version linux "$arch" "$version")"
    rm -f "julia-$version.tar.gz" "julia-$version.tar.gz.*"
    if ! $WGET "$url" -O "julia-$version.tar.gz"; then
      echo "ошибка загрузки julia-$version"
      rm "julia-$version.tar.gz"
      return
    fi
  else              
    echo "уже загружено"
  fi
  if [[ "$LATEST" == "1" ]]; then
    if [ -d "julia-$version" ]; then
      echo "Внимание: Последняя версия $version уже загружена и распакована."
      return
    fi
  fi

  echo "Распаковка архива с julia"
  mkdir -p "julia-$version"
  tar zxf "julia-$version.tar.gz" -C "julia-$version" --strip-components 1

  major=${version:0:3}
  rm -f "$JULIA_INSTALL"/julia{,-"$major",-"$version"}
  julia="$PWD/julia-$version/bin/julia"
  echo "создание символьной ссылки"
  # create symlink
  ln -s "$julia" "$JULIA_INSTALL/julia"
  ln -s "$julia" "$JULIA_INSTALL/julia-$major"
  ln -s "$julia" "$JULIA_INSTALL/julia-$version"
  source ~/.bashrc
}




# --------------------------------------------------------
start_install(){
welcome
check_jupyter_install
confirm_julia
jupyter_install
scilab_kernel_install
octave_kernel_install
bash_kernel_install
wolfram_engine_install
package_installer
}

start_install
