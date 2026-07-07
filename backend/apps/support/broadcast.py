from asgiref.sync import async_to_sync
from channels.layers import get_channel_layer


def broadcast_support_message(*, user_id: int, payload: dict) -> None:
    channel_layer = get_channel_layer()
    if not channel_layer:
        return
    async_to_sync(channel_layer.group_send)(
        f"support_user_{user_id}",
        {"type": "support.message", "payload": payload},
    )