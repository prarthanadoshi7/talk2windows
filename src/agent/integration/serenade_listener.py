import asyncio
import json
import logging
import websockets
import os
from ..core.service import AgentService
from ..config.config import setup_environment

# Set up environment variables for consistent operation
setup_environment()

class SerenadeListener:
    def __init__(self, service: AgentService):
        self.service = service
        self.logger = logging.getLogger(__name__)
        self.uri = "ws://localhost:17373"
        self.heartbeat_task = None

    async def heartbeat(self, websocket):
        """Send heartbeat every 5 seconds."""
        try:
            while True:
                await asyncio.sleep(5)
                await websocket.send(json.dumps({"type": "heartbeat"}))
                self.logger.debug("Sent heartbeat")
        except Exception as e:
            self.logger.error(f"Heartbeat error: {e}")

    async def connect(self):
        """Connect to Serenade WebSocket and handle messages."""
        try:
            async with websockets.connect(self.uri) as websocket:
                self.logger.info("Connected to Serenade WebSocket")
                # Send active
                await websocket.send(json.dumps({"type": "active"}))
                self.logger.info("Sent active message")
                # Start heartbeat
                self.heartbeat_task = asyncio.create_task(self.heartbeat(websocket))
                try:
                    while True:
                        message = await websocket.recv()
                        data = json.loads(message)
                        self.logger.info(f"Received message: {data}")
                        if data.get("type") == "callback":
                            transcript = data.get("transcript", "")
                            if transcript:
                                self.logger.info(f"Processing transcript: {transcript}")
                                # Run the transcript processing in the background to avoid blocking
                                asyncio.create_task(self.service.handle_transcript(transcript))
                            else:
                                self.logger.warning("Received callback without transcript")
                except websockets.exceptions.ConnectionClosed:
                    self.logger.warning("WebSocket connection closed")
                finally:
                    if self.heartbeat_task:
                        self.heartbeat_task.cancel()
                        try:
                            await self.heartbeat_task
                        except asyncio.CancelledError:
                            pass
        except Exception as e:
            self.logger.error(f"Connection error: {e}")

    async def run(self):
        """Main loop with auto-reconnect."""
        while True:
            try:
                await self.connect()
            except Exception as e:
                self.logger.error(f"Connection failed: {e}")
                await asyncio.sleep(5)  # Retry after 5 seconds

if __name__ == "__main__":
    # Configure logging
    logging.basicConfig(
        level=logging.INFO,
        format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
    )
    
    try:
        service = AgentService()
        listener = SerenadeListener(service)
        asyncio.run(listener.run())
    except Exception as e:
        logging.error(f"Failed to start Serenade listener: {e}")