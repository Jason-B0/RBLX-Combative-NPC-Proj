local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Chat = game:GetService("Chat")
return function()
	local folder = ReplicatedStorage.EventNPC
	local specialNPC1 = folder.snpc124123
	local specialNPC2 = folder.snpc7877128938
	local specialNPC3 = folder.snpc88882173
	
	-- set all parents to workspace
	specialNPC1.Parent = workspace.NPC
	specialNPC2.Parent = workspace.NPC
	specialNPC3.Parent = workspace.NPC

    -- conversation
    -- conversation
	task.wait(5)
    Chat:Chat(specialNPC1.Head, "¿Esta es toda la tienda?")
    task.wait(math.random(2, 4))

    Chat:Chat(specialNPC2.Head, "Sí, estamos limpiando el resto hoy.")
    task.wait(math.random(2, 4))

    Chat:Chat(specialNPC1.Head, "Traer a Enrique?")
    task.wait(math.random(2, 4))

    Chat:Chat(
        specialNPC3.Head,
        "Sí, esta vez él es el enchufe. Está en Houston para las rondas."
    )
    task.wait(math.random(2, 4))

    Chat:Chat(specialNPC1.Head, "No está en el mismo pequeño lugar que la última vez, ¿verdad?")
    task.wait(math.random(2, 4))

    Chat:Chat(specialNPC2.Head, "Sí.")
    task.wait(math.random(2, 4))

    Chat:Chat(
        specialNPC1.Head,
        "No puede verse atrapado en una guerra territorial como la última vez."
    )
    task.wait(math.random(2, 4))

    Chat:Chat(specialNPC3.Head, "No creo que lo haga, será inteligente.")
    task.wait(math.random(2, 4))

    Chat:Chat(
        specialNPC2.Head,
        "Bueno, el suministro vence hoy y la mayor parte ya ha sido entregada. Deberíamos estar listos para salir."
    )
    task.wait(math.random(2, 4))

    Chat:Chat(
        specialNPC1.Head,
        "Mañana y luego esperar el siguiente clic en aproximadamente un mes."
    )
    task.wait(math.random(2, 4))

    Chat:Chat(specialNPC3.Head, "Eso es alentador.")
    task.wait(math.random(2, 4))

    Chat:Chat(
        specialNPC1.Head,
        "No lo sé, el muelle ha estado bastante lleno de cerdos estas últimas semanas."
    )
    task.wait(math.random(2, 4))

    Chat:Chat(specialNPC2.Head, "Sí, también estoy empezando a tener dudas sobre este clic.")
    task.wait(math.random(2, 4))

    Chat:Chat(
        specialNPC3.Head,
        "De todos modos, la mayor parte ya ha sido limpiada, no tenemos nada de qué preocuparnos por los niños."
    )
    task.wait(math.random(2, 4))

    Chat:Chat(specialNPC1.Head, "No estaría muy seguro de eso.")
    task.wait(math.random(2, 4))

    Chat:Chat(
        specialNPC2.Head,
        "Dejémoslo en manos de los chicos de respaldo por ahora. Depende de ellos solucionarlo."
    )
    task.wait(math.random(2, 4))

    Chat:Chat(
        specialNPC3.Head,
        "Pero no quiero verme atrapado en una confrontación una de estas noches. No tan temprano..."
    )
    task.wait(math.random(2, 4))

    Chat:Chat(specialNPC1.Head, "Es lo que es Carlo..")
    task.wait(math.random(2, 4))
	
	return specialNPC1, specialNPC2, specialNPC3
end