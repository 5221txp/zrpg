import json


def read_json_file(filepath):
    with open(filepath, mode='r', encoding='utf8') as f:
        return json.loads(f.read());

def write_json_file(filepath, data):
    with open(filepath, mode='w', encoding='utf8') as f:
        return f.write(json.dumps(data))

if __name__ == '__main__':
    data: list = read_json_file('resources/characters2.json')
    w = 12
    h = 8
    # data = sorted(data, key=lambda s: s['x'] * s['x'] + s['y'] * s['y'])
    # data = sorted(data, key=lambda s: (s['x'],s['y']))
    # data = sorted(data, key=lambda s: (s['y'], s['x'] * s['x'] + s['y'] * s['y']))
    data = sorted(data, key=lambda s: s['y'])
    for i in range(0, h):
        start = i * w
        data[i*w:i*w+w] = sorted(data[i*w:i*w+w], key=lambda s: s['x'])
    print(json.dumps(data))