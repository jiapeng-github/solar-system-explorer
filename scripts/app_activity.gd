extends RefCounted
## Focus and application suspension are independent lifecycle conditions.
var focused := true
var paused := false

func handle_notification(what: int) -> void:
	match what:
		Node.NOTIFICATION_APPLICATION_FOCUS_OUT:
			focused = false
		Node.NOTIFICATION_APPLICATION_FOCUS_IN:
			focused = true
		Node.NOTIFICATION_APPLICATION_PAUSED:
			paused = true
		Node.NOTIFICATION_APPLICATION_RESUMED:
			paused = false

func is_active() -> bool:
	return focused and not paused
