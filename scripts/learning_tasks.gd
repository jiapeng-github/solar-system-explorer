extends RefCounted
const TASKS := [
	{"id":"rocky","title":"认识岩石行星","bodies":["mercury","venus","earth","mars"],"pair":[2,3],"mode":"rotation","comparison":"rotation:earth:mars","question":"这四颗行星有什么共同特点？","options":["具有岩石地表","都由气体构成"],"correct":0,"review":"水星、金星、地球和火星是类地行星，具有岩石地表；它们的自转周期并不相同。"},
	{"id":"giants","title":"寻找巨行星","bodies":["jupiter","saturn","uranus","neptune"],"pair":[2,4],"mode":"size","comparison":"size:earth:jupiter","question":"木星与土星属于哪一类？","options":["冰巨行星","气态巨行星"],"correct":1,"review":"木星和土星是气态巨行星，天王星和海王星是冰巨行星。比较图中的直径比不是体积比。"}
]
static func comparison_key(mode: String, a: String, b: String) -> String:
	var pair := [a,b]
	pair.sort()
	return mode+":"+pair[0]+":"+pair[1]
static func ready_for_quiz(task: Dictionary, data: Dictionary) -> bool:
	for id in task.bodies:
		if not data.visited.has(id): return false
	return data.comparisons.has(task.comparison)
