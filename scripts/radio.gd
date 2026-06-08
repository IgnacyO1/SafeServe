extends Node2D
class_name radio_script
@onready var radio = get_node_or_null("HUD/Radio popup") if has_node("HUD/Radio popup") else get_node_or_null("CanvasLayer/HUD/Radio popup")
@onready var map = get_node_or_null("Map") if has_node("Map") else get_node_or_null("CanvasLayer/Map")
@onready var glow = get_node_or_null("HUD/RadioSpriteGlow") 
@onready var radio_sprite = get_node_or_null("HUD/RadioSprite") 
