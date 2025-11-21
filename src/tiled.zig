const std = @import("std");
const Allocator = std.mem.Allocator;
const ParseOptions = std.json.ParseOptions;

pub const Orientation = enum { orthogonal, isometric, staggered, hexagonal };
pub const RenderOrder = enum {
    right_down,
    right_up,
    left_down,
    left_up,

    pub fn jsonParse(
        allocator: std.mem.Allocator,
        source: anytype,
        options: std.json.ParseOptions,
    ) !RenderOrder {
        // const v = source.next();
        std.debug.print("{}\n", .{source.is_end_of_input});
        // if (try source.next()) |key| {
        //     std.debug.print("{s}\n", .{key});
        // }
        const s = try std.json.innerParse([]const u8, allocator, source, options);
        // Match exact strings that Tiled produces:
        // "right-down", "right-up", "left-down", "left-up"
        if (std.mem.eql(u8, s, "right-down")) return RenderOrder.right_down;
        if (std.mem.eql(u8, s, "right-up")) return RenderOrder.right_up;
        if (std.mem.eql(u8, s, "left-down")) return RenderOrder.left_down;
        if (std.mem.eql(u8, s, "left-up")) return RenderOrder.left_up;

        return error.InvalidCharacter;
    }
};
pub const StaggerAxis = enum { x, y };
pub const StaggerIndex = enum { odd, even };
pub const LayerType = enum { tilelayer, objectgroup, imagelayer, group };
pub const DrawOrder = enum { topdown, index };
pub const Encoding = enum { csv, base64 };
pub const Compression = enum { zlib, gzip, zstd };
pub const ObjectAlignment = enum {
    unspecified,
    topleft,
    top,
    topright,
    left,
    center,
    right,
    bottomleft,
    bottom,
    bottomright,
};
pub const FillMode = enum { stretch, preserve_aspect_fit };
pub const TileRenderSize = enum { tile, grid };
pub const GridOrientation = enum { orthogonal, isometric };
pub const WangSetType = enum { corner, edge, mixed };

// --- Core Structs ---
pub const Property = struct {
    name: []const u8,
    type: []const u8,
    // value: std.json.Value,
    value: []const u8,
};

pub const Point = struct { x: f64, y: f64 };

pub const ObjectText = struct {
    text: []const u8,
    wrap: ?bool = null,
    color: ?[]const u8 = null,
    fontfamily: ?[]const u8 = null,
    pixelsize: ?i32 = null,
    bold: ?bool = null,
    italic: ?bool = null,
    underline: ?bool = null,
    strikeout: ?bool = null,
    kerning: ?bool = null,
    halign: ?[]const u8 = null,
    valign: ?[]const u8 = null,
};

pub const Object = struct {
    id: i32,
    name: []const u8,
    type: []const u8,
    x: f64,
    y: f64,
    width: ?f64 = null,
    height: ?f64 = null,
    rotation: ?f64 = null,
    visible: ?bool = null,
    class: ?[]const u8 = null,
    gid: ?i32 = null,
    properties: ?[]Property = null,
    template: ?[]const u8 = null,
    ellipse: ?bool = null,
    point: ?bool = null,
    polygon: ?[]Point = null,
    polyline: ?[]Point = null,
    text: ?ObjectText = null,
};

pub const Chunk = struct {
    data: std.json.Value,
    height: i32,
    width: i32,
    x: i32,
    y: i32,
};

pub const Layer = struct {
    chunks: ?[]Chunk = null,
    class: ?[]const u8 = null,
    compression: ?Compression = null,
    data: ?std.json.Value = null,
    draworder: ?DrawOrder = null,
    encoding: ?Encoding = null,
    height: ?i32 = null,
    id: i32,
    image: ?[]const u8 = null,
    imageheight: ?i32 = null,
    imagewidth: ?i32 = null,
    layers: ?[]Layer = null,
    locked: ?bool = null,
    name: []const u8,
    opacity: f64,
    properties: ?[]Property = null,
    transparentcolor: ?[]const u8 = null,
    tintcolor: ?[]const u8 = null,
    type: LayerType,
    visible: bool,
    width: ?i32 = null,
    x: i32,
    y: i32,
};

pub const TileOffset = struct {
    x: i32,
    y: i32,
};

pub const TileTransformations = struct {
    hflip: bool,
    vflip: bool,
    rotate: bool,
    preferuntransformed: bool,
};

pub const Terrain = struct {
    name: []const u8,
    tile: i32,
};

pub const WangColor = struct {
    class: ?[]const u8 = null,
    color: []const u8,
    name: []const u8,
    probability: f64,
    tile: i32,
};

pub const WangTile = struct {
    tileid: i32,
    wangid: []const u8,
};

pub const WangSet = struct {
    class: ?[]const u8 = null,
    colors: []WangColor,
    name: []const u8,
    properties: ?[]Property = null,
    tile: i32,
    type: WangSetType,
    wangtiles: []WangTile,
};

pub const TilesetGrid = struct {
    height: i32,
    orientation: GridOrientation,
    width: i32,
};

pub const Tile = struct {
    id: i32,
    animation: ?[]TileFrame = null,
    class: ?[]const u8 = null,
    image: ?[]const u8 = null,
    imageheight: ?i32 = null,
    imagewidth: ?i32 = null,
    objectgroup: ?Layer = null,
    properties: ?[]Property = null,
    terrain: ?[]i32 = null,
    probability: ?f64 = null,
};

pub const TileFrame = struct {
    duration: i32,
    tileid: i32,
};

pub const Tileset = struct {
    backgroundcolor: ?[]const u8 = null,
    class: ?[]const u8 = null,
    columns: i32,
    fillmode: ?FillMode = null,
    firstgid: i32,
    grid: ?TilesetGrid = null,
    image: ?[]const u8 = null,
    imageheight: ?i32 = null,
    imagewidth: ?i32 = null,
    margin: i32,
    name: []const u8,
    objectalignment: ?ObjectAlignment = null,
    properties: ?[]Property = null,
    source: ?[]const u8 = null,
    spacing: i32,
    terrains: ?[]Terrain = null,
    tilecount: i32,
    tiledversion: ?[]const u8 = null,
    tileheight: i32,
    tileoffset: ?TileOffset = null,
    tilerendersize: ?TileRenderSize = null,
    tiles: ?[]Tile = null,
    tilewidth: i32,
    transformations: ?TileTransformations = null,
    transparentcolor: ?[]const u8 = null,
    type: ?[]const u8 = null,
    version: ?[]const u8 = null,
    wangsets: ?[]WangSet = null,
};

pub const Map = struct {
    backgroundcolor: ?[]const u8 = null,
    class: ?[]const u8 = null,
    compressionlevel: i32,
    height: i32,
    hexsidelength: ?i32 = null,
    infinite: bool,
    layers: []Layer,
    nextlayerid: i32,
    nextobjectid: i32,
    orientation: Orientation,
    parallaxoriginx: ?f64 = null,
    parallaxoriginy: ?f64 = null,
    properties: ?[]Property = null,
    renderorder: RenderOrder,
    staggeraxis: ?StaggerAxis = null,
    staggerindex: ?StaggerIndex = null,
    tiledversion: []const u8,
    tileheight: i32,
    tilesets: []Tileset,
    tilewidth: i32,
    type: ?[]const u8 = "map",
    version: []const u8,
    width: i32,
};
