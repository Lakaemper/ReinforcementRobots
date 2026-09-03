import time
import gymnasium as gym
from stable_baselines3 import SAC
from stable_baselines3.common.callbacks import BaseCallback, CheckpointCallback, CallbackList

TRAIN_MINUTES = 90
MODEL_NAME = "sac_bipedalwalker_90min"


class TimeLimitCallback(BaseCallback):
    def __init__(self, max_minutes, verbose=0):
        super().__init__(verbose)
        self.max_seconds = max_minutes * 60
        self.start_time = None

    def _on_training_start(self):
        self.start_time = time.time()

    def _on_step(self):
        elapsed = time.time() - self.start_time
        if elapsed >= self.max_seconds:
            print(f"Time limit reached ({elapsed / 60:.1f} min, {self.num_timesteps} steps) - stopping.")
            return False
        return True


env = gym.make("BipedalWalker-v3")
model = SAC("MlpPolicy", env, verbose=1)

callbacks = CallbackList([
    TimeLimitCallback(max_minutes=TRAIN_MINUTES, verbose=1),
    CheckpointCallback(save_freq=20_000, save_path="./checkpoints", name_prefix=MODEL_NAME),
])

# total_timesteps is just an upper bound the time limit will interrupt well before
model.learn(total_timesteps=50_000_000, callback=callbacks)
model.save(MODEL_NAME)

eval_env = gym.make("BipedalWalker-v3", render_mode="human")
obs, info = eval_env.reset()
for _ in range(500):
    action, _ = model.predict(obs, deterministic=True)
    obs, reward, terminated, truncated, info = eval_env.step(action)
    if terminated or truncated:
        obs, info = eval_env.reset()
eval_env.close()
