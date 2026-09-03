import gymnasium as gym
from stable_baselines3 import SAC

env = gym.make("BipedalWalker-v3")
model = SAC("MlpPolicy", env, verbose=1)
model.learn(total_timesteps=10_000)
model.save("sac_bipedalwalker_smoke_test")

eval_env = gym.make("BipedalWalker-v3", render_mode="human")
obs, info = eval_env.reset()
for _ in range(500):
    action, _ = model.predict(obs, deterministic=True)
    obs, reward, terminated, truncated, info = eval_env.step(action)
    if terminated or truncated:
        obs, info = eval_env.reset()
eval_env.close()
