const std = @import("std");

pub const Map = struct {
    width: i32,
    height: i32,
    tilewidth: i32,
    tileheight: i32,
    infinite: ?bool,
    orientation: []const u8,
    renderorder: []const u8,
    version: i32,
    tiledversion: []const u8,
    nextlayerid: ?i32,
    nextobjectid: ?i32,
    layers: []Layer,
    tilesets: []Tileset,
    properties: ?[]Property = null,
    backgroundcolor: ?[]const u8 = null,
    compressionlevel: ?i32 = null,

    pub fn fromJson(allocator: *std.mem.Allocator, json: std.json.Value) !*Map {
        const map = try allocator.create(Map);
        const obj = try json.Object();
        map.width = try obj.getInt("width");
        map.height = try obj.getInt("height");
        map.tilewidth = try obj.getInt("tilewidth");
        map.tileheight = try obj.getInt("tileheight");
        map.infinite = try obj.getBool("infinite");
        map.orientation = try obj.getString("orientation");
        map.renderorder = try obj.getString("renderorder");
        map.version = try obj.getString("version");
        map.tiledversion = try obj.getString("tiledversion");
        map.nextlayerid = try obj.getInt("nextlayerid");
        map.nextobjectid = try obj.getInt("nextobjectid");

        // Parse layers
        const layers_json = try obj.getArray("layers");
        map.layers = try allocator.alloc(Layer, layers_json.len);
        for (layers_json, 0..) |layer_json, i| {
            map.layers[i] = try Layer.fromJson(allocator, layer_json);
        }

        // Parse tilesets
        const tilesets_json = try obj.getArray("tilesets");
        map.tilesets = try allocator.alloc(Tileset, tilesets_json.len);
        for (tilesets_json, 0..) |ts_json, i| {
            map.tilesets[i] = try Tileset.fromJson(allocator, ts_json);
        }

        // Optional properties
        if (obj.has("properties")) {
            const props_json = try obj.getArray("properties");
            map.properties = try allocator.alloc(Property, props_json.len);
            for (props_json, 0..) |p_json, i| {
                map.properties.?[i] = try Property.fromJson(allocator, p_json);
            }
        }

        return map;
    }
};

pub const Layer = struct {
    id: i32,
    name: []const u8,
    type_: []const u8,
    visible: bool,
    opacity: f64,
    offsetx: f64,
    offsety: f64,
    data: ?[]u32 = null,
    chunks: ?[]Chunk = null,
    objects: ?[]Object = null,
    properties: ?[]Property = null,

    pub fn fromJson(allocator: *std.mem.Allocator, json: std.json.Value) !Layer {
        const obj = try json.Object();
        var layer = Layer{
            .id = try obj.getInt("id"),
            .name = try obj.getString("name"),
            .type_ = try obj.getString("type"),
            .visible = try obj.getBool("visible"),
            .opacity = try obj.getFloat("opacity"),
            .offsetx = try obj.getFloat("offsetx"),
            .offsety = try obj.getFloat("offsety"),
            .data = null,
            .chunks = null,
            .objects = null,
            .properties = null,
        };

        if (obj.has("data")) {
            const data_json = try obj.getArray("data");
            layer.data = try allocator.alloc(u32, data_json.len);
            for (data_json, 0..) |v, i| layer.data.?[i] = try v.Int();
        }

        if (obj.has("chunks")) {
            const chunks_json = try obj.getArray("chunks");
            layer.chunks = try allocator.alloc(Chunk, chunks_json.len);
            for (chunks_json, 0..) |c_json, i| layer.chunks.?[i] = try Chunk.fromJson(allocator, c_json);
        }

        if (obj.has("objects")) {
            const objs_json = try obj.getArray("objects");
            layer.objects = try allocator.alloc(Object, objs_json.len);
            for (objs_json, 0..) |o_json, i| layer.objects.?[i] = try Object.fromJson(allocator, o_json);
        }

        if (obj.has("properties")) {
            const props_json = try obj.getArray("properties");
            layer.properties = try allocator.alloc(Property, props_json.len);
            for (props_json, 0..) |p_json, i| layer.properties.?[i] = try Property.fromJson(allocator, p_json);
        }

        return layer;
    }
};

pub const Chunk = struct {
    data: []u32,
    width: i32,
    height: i32,
    x: i32,
    y: i32,

    pub fn fromJson(allocator: *std.mem.Allocator, json: std.json.Value) !Chunk {
        const obj = try json.Object();
        const data_json = try obj.getArray("data");
        var chunk = Chunk{
            .data = try allocator.alloc(u32, data_json.len),
            .width = try obj.getInt("width"),
            .height = try obj.getInt("height"),
            .x = try obj.getInt("x"),
            .y = try obj.getInt("y"),
        };
        for (data_json, 0..) |v, i| chunk.data[i] = try v.Int();
        return chunk;
    }
};

pub const Object = struct {
    id: i32,
    name: []const u8,
    type_: []const u8,
    x: f64,
    y: f64,
    width: f64,
    height: f64,
    rotation: f64,
    visible: bool,
    properties: ?[]Property = null,

    pub fn fromJson(allocator: *std.mem.Allocator, json: std.json.Value) !Object {
        const obj = try json.Object();
        var o = Object{
            .id = try obj.getInt("id"),
            .name = try obj.getString("name"),
            .type_ = try obj.getString("type"),
            .x = try obj.getFloat("x"),
            .y = try obj.getFloat("y"),
            .width = try obj.getFloat("width"),
            .height = try obj.getFloat("height"),
            .rotation = try obj.getFloat("rotation"),
            .visible = try obj.getBool("visible"),
        };

        if (obj.has("properties")) {
            const props_json = try obj.getArray("properties");
            o.properties = try allocator.alloc(Property, props_json.len);
            for (props_json, 0..) |p_json, i| o.properties.?[i] = try Property.fromJson(allocator, p_json);
        }

        return o;
    }
};

pub const Property = struct {
    name: []const u8,
    type: []const u8,
    value: std.json.Value,

    pub fn fromJson(json: std.json.Value) !Property {
        const obj = try json.Object();
        return Property{
            .name = try obj.getString("name"),
            .type_ = try obj.getString("type"),
            .value = try obj.get("value"),
        };
    }
};

pub const Tileset = struct {
    firstgid: i32,
    source: ?[]const u8,
    name: []const u8,
    tilewidth: i32,
    tileheight: i32,

    pub fn fromJson(json: std.json.Value) !Tileset {
        const obj = try json.Object();
        return Tileset{
            .firstgid = try obj.getInt("firstgid"),
            .source = if (obj.has("source")) try obj.getString("source") else null,
            .name = try obj.getString("name"),
            .tilewidth = try obj.getInt("tilewidth"),
            .tileheight = try obj.getInt("tileheight"),
        };
    }
};
