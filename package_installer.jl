import REPL, Pkg
using REPL.TerminalMenus
import REPL.TerminalMenus: header

 header(m::MultiSelectMenu) = "нажмите: Enter - выбрать, a - выбрать все, n - убрать все, d - далее, q - отмена"


DEFAULT_PACKAGES = Dict("стандартный набор" =>["Plots", "IJulia", "Pluto", "PyCall", "SpecialFunctions", "Images"],
                "Построение графиков" => ["Plots", "Makie", "Gradfly", "GLMakie"],
                "разработка приложений с графическим интерфейсом" => ["QML"],
                "Дополнительные структуры данных" => ["DataStructures", "StructArrays", "DecisionTree"],
                "Дифференциальные уравнения" => ["DifferentialEquations", "ModelingToolkit"],
                "Символьные вычисления" => ["Symbolics","SymbolicUtils", "ModelingToolkit"],
                "методы оптимизации" => ["Optim","JuMP","BlackBoxOptim" ],
                "Интерполяции" => ["Interpolations"],
                "Интегрирование" => ["QuadGK", "Roots", "Calculus"],
                "Нелинейные уравнения" => ["NLsolve"],
                "Стохастический анализ" => ["CategoricalArrays", "Clustering","Combinatorics",
                                            "Distributions", "GLM", "StatsBase", 
                                            "StatsModels", "StatsPlots", "MultivariateStats","Measures"]
)               
function introdution()
    println("Добро пожаловать в установщик пакетов для julia")
    println("На выбор пользователю предлагается установить следующие наборы пакетов:")
    for (key, value) in DEFAULT_PACKAGES
        println("$key: ", join(value, ", "))
    end
end

function names_list(d)
    menu = collect(keys(d))
    return menu
end


function printmenu()
    set_names = names_list(DEFAULT_PACKAGES)

    menu = TerminalMenus.MultiSelectMenu(set_names)
    choices = TerminalMenus.request("Выберите библиотеки которые хотите установить:", menu)
    selected_items = []

    if length(choices) > 0
        println("Выбрано:")
        for i in choices
            println("- ", set_names[i])
        push!(selected_items, set_names[i])
        end
    else
        println("отменено.")
        exit(1);
    end
    return selected_items
end


#function edit_packages(package_list)
 #   println("Выберите наборы, которые нужно отредактировать:")
#end


function confirm_install(package_list)
   # println("вручную выбрать пакеты для установки? ")
   println("Установить выбранные наборы?")
    answer = match(r"^[yYnN]", readline()).match
    if answer in ("y", "Y")
        start_install(package_list)
    else
        println("Установка отменена")
        exit()
    end
end

 function start_install(package_list)
    for name in package_list
        packages  = get(DEFAULT_PACKAGES, name, 0)
        for package in packages
            println("Установка: $package")
            Pkg.add(package)
        end
    end 
end


function main()
    introdution()
    items = printmenu()
    confirm_install(items)
    exit()
end

main()
