extends Node

signal event_logged(symbol: String, message: String)

func log(symbol: String, message: String) -> void:
	event_logged.emit(symbol, message)
