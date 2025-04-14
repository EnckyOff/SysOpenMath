import REPL, Pkg
using REPL.TerminalMenus

# Изменение заголовка меню
REPL.TerminalMenus.header(m::REPL.TerminalMenus.MultiSelectMenu) = "Нажмите: Enter - выбрать, a - выбрать все, n - убрать всё, d - далее, q - отмена"

JULIA_PACKAGES = Dict(
    "Стандартный набор" => ["Plots", "IJulia", "Pluto", "PyCall", "SpecialFunctions", "Images"],
    "Построение графиков" => ["Plots", "Makie", "Gadfly", "GLMakie"],
    "Разработка приложений с графическим интерфейсом" => ["QML"],
    "Дополнительные структуры данных" => ["DataStructures", "StructArrays", "DecisionTree"],
    "Дифференциальные уравнения" => ["DifferentialEquations", "ModelingToolkit"],
    "Символьные вычисления" => ["Symbolics", "SymbolicUtils", "ModelingToolkit"],
    "Методы оптимизации" => ["Optim", "JuMP", "BlackBoxOptim"],
    "Интерполяции" => ["Interpolations"],
    "Интегрирование" => ["QuadGK", "Roots", "Calculus"],
    "Нелинейные уравнения" => ["NLsolve"],
    "Стохастический анализ" => ["CategoricalArrays", "Clustering", "Combinatorics", "Distributions", "GLM", "StatsBase", "StatsModels", "StatsPlots", "MultivariateStats", "Measures"]
)

function introduction()
    println("Добро пожаловать в установщик пакетов для Julia")
    println("На выбор пользователю предлагается установить следующие наборы пакетов:")
    for (key, value) in JULIA_PACKAGES
        println("$key: ", join(value, ", "))
    end
end

function select_packages_for_category(category, packages)
    menu = REPL.TerminalMenus.MultiSelectMenu(packages)
    println("\nКатегория: $category")
    choices = request("Выберите пакеты для установки:", menu)
    if isempty(choices)
        println("Категория '$category' пропущена.")
        return []
    end
    return [packages[i] for i in choices]
end

function confirm_install(packages_to_install)
    println("\nВы собираетесь установить следующие пакеты:")
    println(join(packages_to_install, ", "))
    print("Продолжить? (y/n): ")
    answer = lowercase(readline())
    if !(answer == "y")
        println("Установка отменена.")
        exit(0)
    end
end

function install_packages(packages_to_install)
    for package in packages_to_install
        println("Установка: $package")
        Pkg.add(package)
    end
end

function main()
    introduction()
    all_packages = []

    for (category, packages) in JULIA_PACKAGES
        selected_packages = select_packages_for_category(category, packages)
        append!(all_packages, selected_packages)
    end

    if isempty(all_packages)
        println("Не выбрано ни одного пакета. Выход.")
        exit(0)
    end

    confirm_install(all_packages)
    install_packages(all_packages)
    println("Установка завершена.")
end

main()