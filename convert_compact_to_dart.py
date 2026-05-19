import joblib
import m2cgen as m2c

models = [
    ('building_occupancy', None),
    ('user_behavior_raed', None),
    ('iot_mental_health', None),
]

for name, _ in models:
    print(f"Converting {name}...")
    model = joblib.load(f'trained_models/{name}.pkl')
    code = m2c.export_to_dart(model, function_name=f'predict{name.replace("_", "").title()}')
    filepath = f'lib/generated_models/{name}.dart'
    with open(filepath, 'w') as f:
        f.write(code)
    print(f"  -> {filepath} ({len(code)} chars)")

print("\nDone!")
