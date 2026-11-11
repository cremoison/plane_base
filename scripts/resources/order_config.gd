extends Resource
class_name OrderConfig

@export var title : String
@export var desc : String

@export var id : int
@export var destination : String 
@export var destination_position : Vector3 # IN FUTURO: questa verrà ottenuta direttamente dalla risorsa destinazione

@export var reward : int # array of resources for the player after delivering the order 

@export var cargo : CargoConfig

