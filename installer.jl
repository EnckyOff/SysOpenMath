import REPL, Pkg
using REPL.TerminalMenus



DEFAULT_PACKAGES = Dict("стандартный набор" =>["Plots", "IJulia", "Pluto"],
                "контейнеры данных" => ["Dataframes","CSV", "ExcelFiles", "StructArrays"],
                "дифференциальные уравнения" => ["DifferentialEquations"])


function introdution()
    println("Добро пожаловать в инсталлятор пакетов для julia")
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
    println(set_names)
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


function confirm_install(package_list)
    println("Начать установку выбранных наборов?")
    println("Введите Y или N:")
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
end

main()
