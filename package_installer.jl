import REPL, Pkg
using REPL.TerminalMenus
REPL.TerminalMenus.header(m::REPL.TerminalMenus.MultiSelectMenu) = "Нажмите: Enter - выбрать, a - выбрать все, n - убрать всё, d - далее, ctrl+c - отмена"

# Julia packages
JULIA_PACKAGES = Dict(
    "Стандартный набор" => ["Plots", "Pluto", "PyCall", "SpecialFunctions", "Images"],
    "Построение графиков" => ["Makie", "Gadfly", "GLMakie", "Graphics", "PyPlot"],
    "Разработка приложений с графическим интерфейсом" => ["QML", "GTK"],
    "Дополнительные структуры данных" => ["DataStructures", "StructArrays", "DecisionTree"],
    "Дифференциальные уравнения" => ["DifferentialEquations", "ModelingToolkit"],
    "Символьные вычисления" => ["Symbolics", "SymbolicUtils", "ModelingToolkit"],
    "Методы оптимизации" => ["Optim", "JuMP", "BlackBoxOptim"],
    "Интерполяции" => ["Interpolations"],
    "Интегрирование" => ["QuadGK", "Roots", "Calculus"],
    "Нелинейные уравнения" => ["NLsolve"],
    "Стохастический анализ" => [
        "CategoricalArrays", "Clustering", "Combinatorics", 
         "Distributions", "GLM", "StatsBase", "StatsModels", "StatsPlots",
         "MultivariateStats", "Measures"
    ]
)

# Python Packages
PYTHON_PACKAGES = Dict(
    "Стандартный набор" => ["numpy", "pandas", "scipy", "sympy"],
    "Визуализация" => ["seaborn", "plotly"],
    "Работа с изображениями" => ["opencv-python", "Pillow"],
    "Математика высокой точности" => ["mpmath"],
    "Машинное обучение и глубокое обучение" => ["scikit-learn", "torch", "tensorflow", "torchvision", "torchaudio"]
)

function introduction()
    println("Добро пожаловать в установщик пакетов для Julia и Python")
    println("На выбор пользователю предлагается установить следующие наборы пакетов:")
    println("\nJulia-пакеты:")
    for (key, value) in JULIA_PACKAGES
        println("$key: ", join(value, ", "))
    end
    println("\nPython-пакеты:")
    for (key, value) in PYTHON_PACKAGES
        println("$key: ", join(value, ", "))
    end
end

function select_packages_for_category(category, packages)
    menu = REPL.TerminalMenus.MultiSelectMenu(packages)
    println("\nКатегория: $category")
    try
        choices = request("Выберите пакеты для установки:", menu)
        if isempty(choices)
            println("Категория '$category' пропущена.")
            return []
        end
        return [packages[i] for i in choices]
    catch e
        if isa(e, InterruptException)
            println("\nВыход")
            exit(0)
        else
            rethrow(e)
        end
    end
    return [packages[i] for i in choices]
end

function confirm_install(julia_packages, python_packages)
    println("\nВы собираетесь установить следующие Julia-пакеты:")
    println(join(julia_packages, ", "))
    println("\nИ следующие Python-пакеты:")
    println(join(python_packages, ", "))
    print("Продолжить? (y/n): ")
    answer = lowercase(readline())
    if !(answer == "y")
        println("Установка отменена.")
        exit(0)
    end
end

function install_julia_packages(packages)
    for package in packages
        println("Установка Julia-пакета: $package")
        Pkg.add(package)
    end
    Pkg.add("IJulia")
end

function install_python_packages(packages)
    use_pipx_bool = get(ENV, "USE_PIPX", "0") == "1"
    for package in packages
        println("Установка Python-пакета: $package")
        if use_pipx_bool
            run(`pipx inject jupyter $package`)
        else
            run(`python3 -m pip install --user $package`)
        end
    end
end

function main()
    introduction()
    julia_to_install = []
    python_to_install = []

    for (category, packages) in JULIA_PACKAGES
        selected = select_packages_for_category(category, packages)
        append!(julia_to_install, selected)
    end

    for (category, packages) in PYTHON_PACKAGES
        selected = select_packages_for_category(category, packages)
        append!(python_to_install, selected)
    end

    if isempty(julia_to_install) && isempty(python_to_install)
        println("Не выбрано ни одного пакета. Выход.")
        exit(0)
    end

    confirm_install(julia_to_install, python_to_install)
    install_julia_packages(julia_to_install)
    install_python_packages(python_to_install)
    println("\nУстановка завершена.")
end


main()