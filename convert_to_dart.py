import joblib
import m2cgen as m2c
import os

os.makedirs('lib/generated_models', exist_ok=True)

models = [
    ('egg_production', 'regression'),
    ('green_building', 'regression'),
    ('herbal_plant_health', 'classification'),
    ('iot_air_quality', 'regression'),
    ('smart_library', 'classification'),
    ('building_occupancy', 'classification'),
    ('user_behavior_raed', 'classification'),
    ('iot_mental_health', 'regression'),
]

for name, model_type in models:
    print(f"Converting {name}...")
    model = joblib.load(f'trained_models/{name}.pkl')
    code = m2c.export_to_dart(model, function_name=f'predict{name.replace("_", "").title()}')
    filepath = f'lib/generated_models/{name}.dart'
    with open(filepath, 'w') as f:
        f.write(code)
    print(f"  -> {filepath} ({len(code)} chars)")

print("\nDone!")
