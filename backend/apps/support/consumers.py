from channels.db import database_sync_to_async
from channels.generic.websocket import AsyncJsonWebsocketConsumer
from django.contrib.auth.models import AnonymousUser

from .models import SupportConversation, SupportMessage
from .serializers import SupportMessageSerializer
from .views import _get_or_create_open_conversation


class SupportChatConsumer(AsyncJsonWebsocketConsumer):
    async def connect(self):
        user = self.scope.get("user")
        if not user or isinstance(user, AnonymousUser) or not user.is_authenticated:
            await self.close()
            return

        self.user = user
        self.group_name = f"support_user_{user.id}"
        await self.channel_layer.group_add(self.group_name, self.channel_name)
        await self.accept()
        await self.send_json({"type": "connected", "detail": "Live chat connected."})

    async def disconnect(self, close_code):
        if hasattr(self, "group_name"):
            await self.channel_layer.group_discard(self.group_name, self.channel_name)

    async def receive_json(self, content, **kwargs):
        body = (content.get("body") or "").strip()
        if not body:
            return

        message = await self._save_user_message(body)
        payload = SupportMessageSerializer(message).data
        await self.send_json({"type": "message", "message": payload})

    async def support_message(self, event):
        await self.send_json({"type": "message", "message": event["payload"]})

    @database_sync_to_async
    def _save_user_message(self, body: str) -> SupportMessage:
        conversation = _get_or_create_open_conversation(self.user)
        return SupportMessage.objects.create(conversation=conversation, sender_type="user", body=body)