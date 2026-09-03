import gymnasium as gym
from stable_baselines3 import SAC

model = SAC.load("sac_bipedalwalker_smoke_test")

env = gym.make("BipedalWalker-v3", render_mode="human")
obs, info = env.reset()
for _ in range(1000):
    action, _ = model.predict(obs, deterministic=True)
    obs, reward, terminated, truncated, info = env.step(action)
    if terminated or truncated:
        obs, info = env.reset()
env.close()
