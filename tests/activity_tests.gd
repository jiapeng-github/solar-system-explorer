extends SceneTree
const Activity = preload("res://scripts/app_activity.gd")
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)

func run() -> void:
	var activity = Activity.new()
	check(activity.is_active(), "A new application begins active")
	activity.handle_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	check(not activity.is_active() and not activity.paused, "Focus loss alone makes the application inactive")
	activity.handle_notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(activity.is_active(), "Focus return reactivates an application that was not paused")
	activity.handle_notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	check(not activity.is_active() and activity.focused, "Pause alone makes the application inactive")
	activity.handle_notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(activity.is_active(), "Resume reactivates a focused application")

	# Either return notification can arrive first. Neither may clear the other
	# independent condition, even if the operating system repeats notifications.
	for leave_order in [
		[Node.NOTIFICATION_APPLICATION_FOCUS_OUT, Node.NOTIFICATION_APPLICATION_PAUSED],
		[Node.NOTIFICATION_APPLICATION_PAUSED, Node.NOTIFICATION_APPLICATION_FOCUS_OUT],
	]:
		for return_order in [
			[Node.NOTIFICATION_APPLICATION_RESUMED, Node.NOTIFICATION_APPLICATION_FOCUS_IN],
			[Node.NOTIFICATION_APPLICATION_FOCUS_IN, Node.NOTIFICATION_APPLICATION_RESUMED],
		]:
			activity = Activity.new()
			for event in leave_order:
				activity.handle_notification(event)
				activity.handle_notification(event)
				check(not activity.is_active(), "Repeated leave notifications remain inactive")
			check(not activity.focused and activity.paused, "Both leave conditions are retained")
			activity.handle_notification(return_order[0])
			activity.handle_notification(return_order[0])
			check(not activity.is_active(), "First repeated return notification cannot clear the other condition")
			activity.handle_notification(Node.NOTIFICATION_PROCESS)
			check(not activity.is_active(), "Unrelated notifications cannot reactivate the application")
			activity.handle_notification(return_order[1])
			activity.handle_notification(return_order[1])
			check(activity.is_active(), "Only clearing both conditions restores activity")

	# A focus-in notification may also arrive while the application is still
	# suspended, without any preceding focus-out notification.
	activity = Activity.new()
	activity.handle_notification(Node.NOTIFICATION_APPLICATION_PAUSED)
	activity.handle_notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(not activity.is_active() and activity.paused, "Focus-in does not cancel application suspension")
	activity.handle_notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(activity.is_active(), "Resume clears the remaining suspension condition")
	activity.handle_notification(Node.NOTIFICATION_APPLICATION_FOCUS_OUT)
	activity.handle_notification(Node.NOTIFICATION_APPLICATION_RESUMED)
	check(not activity.is_active() and not activity.focused, "Resume does not cancel focus loss")
	activity.handle_notification(Node.NOTIFICATION_APPLICATION_FOCUS_IN)
	check(activity.is_active(), "Focus-in clears the remaining focus condition")

	print("PASS: independent pause/focus lifecycle, notification ordering and duplicate notifications" if failures.is_empty() else str(failures))
	quit(0 if failures.is_empty() else 1)
