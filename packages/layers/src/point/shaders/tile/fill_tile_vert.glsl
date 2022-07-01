attribute vec4 a_Color;
attribute vec3 a_Position;
attribute vec3 a_Extrude;
attribute float a_Size;
attribute float a_Shape;

varying mat4 styleMappingMat; // 用于将在顶点着色器中计算好的样式值传递给片元

uniform mat4 u_ModelMatrix;
uniform mat4 u_Mvp;
uniform float u_isMeter;

uniform vec2 u_tileOrigin;
uniform float u_coord;

varying vec4 v_data;
varying vec4 v_color;
varying float v_radius;

uniform float u_opacity : 1;
uniform float u_stroke_opacity : 1;
uniform float u_stroke_width : 2;
uniform vec4 u_stroke_color : [0.0, 0.0, 0.0, 0.0];
uniform vec2 u_offsets;

uniform float u_blur : 0.0;

#pragma include "styleMapping"
#pragma include "styleMappingCalOpacity"
#pragma include "styleMappingCalStrokeOpacity"
#pragma include "styleMappingCalStrokeWidth"

#pragma include "projection"
#pragma include "picking"

void main() {
  vec3 extrude = a_Extrude;
  float shape_type = a_Shape;
  float newSize = setPickingSize(a_Size);

  // cal style mapping - 数据纹理映射部分的计算
  styleMappingMat = mat4(
    0.0, 0.0, 0.0, 0.0, // opacity - strokeOpacity - strokeWidth - empty
    0.0, 0.0, 0.0, 0.0, // strokeR - strokeG - strokeB - strokeA
    0.0, 0.0, 0.0, 0.0, // offsets[0] - offsets[1]
    0.0, 0.0, 0.0, 0.0
  );

  float rowCount = u_cellTypeLayout[0][0];    // 当前的数据纹理有几行
  float columnCount = u_cellTypeLayout[0][1]; // 当看到数据纹理有几列
  float columnWidth = 1.0/columnCount;  // 列宽
  float rowHeight = 1.0/rowCount;       // 行高
  float cellCount = calCellCount(); // opacity - strokeOpacity - strokeWidth - stroke - offsets
  float id = a_vertexId; // 第n个顶点
  float cellCurrentRow = floor(id * cellCount / columnCount) + 1.0; // 起始点在第几行
  float cellCurrentColumn = mod(id * cellCount, columnCount) + 1.0; // 起始点在第几列
  
  // cell 固定顺序 opacity -> strokeOpacity -> strokeWidth -> stroke ... 
  // 按顺序从 cell 中取值、若没有则自动往下取值
  float textureOffset = 0.0; // 在 cell 中取值的偏移量

  vec2 opacityAndOffset = calOpacityAndOffset(cellCurrentRow, cellCurrentColumn, columnCount, textureOffset, columnWidth, rowHeight);
  styleMappingMat[0][0] = opacityAndOffset.r;
  textureOffset = opacityAndOffset.g;

  vec2 strokeOpacityAndOffset = calStrokeOpacityAndOffset(cellCurrentRow, cellCurrentColumn, columnCount, textureOffset, columnWidth, rowHeight);
  styleMappingMat[0][1] = strokeOpacityAndOffset.r;
  textureOffset = strokeOpacityAndOffset.g;

  vec2 strokeWidthAndOffset = calStrokeWidthAndOffset(cellCurrentRow, cellCurrentColumn, columnCount, textureOffset, columnWidth, rowHeight);
  styleMappingMat[0][2] = strokeWidthAndOffset.r;
  textureOffset = strokeWidthAndOffset.g;

  vec4 textrueStroke = vec4(-1.0, -1.0, -1.0, -1.0);
  if(hasStroke()) {
    vec2 valueRPos = nextPos(cellCurrentRow, cellCurrentColumn, columnCount, textureOffset);
    styleMappingMat[1][0] = pos2value(valueRPos, columnWidth, rowHeight); // R
    textureOffset += 1.0;

    vec2 valueGPos = nextPos(cellCurrentRow, cellCurrentColumn, columnCount, textureOffset);
    styleMappingMat[1][1] = pos2value(valueGPos, columnWidth, rowHeight); // G
    textureOffset += 1.0;

    vec2 valueBPos = nextPos(cellCurrentRow, cellCurrentColumn, columnCount, textureOffset);
    styleMappingMat[1][2] = pos2value(valueBPos, columnWidth, rowHeight); // B
    textureOffset += 1.0;

    vec2 valueAPos = nextPos(cellCurrentRow, cellCurrentColumn, columnCount, textureOffset);
    styleMappingMat[1][3] = pos2value(valueAPos, columnWidth, rowHeight); // A
    textureOffset += 1.0;
  } else {
    if(u_stroke_color == vec4(0.0)) {
      styleMappingMat[1][0] = v_color.r;
      styleMappingMat[1][1] = v_color.g;
      styleMappingMat[1][2] = v_color.b;
      styleMappingMat[1][3] = v_color.a;
    } else {
      styleMappingMat[1][0] = u_stroke_color.r;
      styleMappingMat[1][1] = u_stroke_color.g;
      styleMappingMat[1][2] = u_stroke_color.b;
      styleMappingMat[1][3] = u_stroke_color.a;
    }
  }

  vec2 textrueOffsets = vec2(0.0, 0.0);
  if(hasOffsets()) {
    vec2 valueXPos = nextPos(cellCurrentRow, cellCurrentColumn, columnCount, textureOffset);
    textrueOffsets.r = pos2value(valueXPos, columnWidth, rowHeight); // x
    textureOffset += 1.0;

    vec2 valueYPos = nextPos(cellCurrentRow, cellCurrentColumn, columnCount, textureOffset);
    textrueOffsets.g = pos2value(valueYPos, columnWidth, rowHeight); // x
    textureOffset += 1.0;
  } else {
    textrueOffsets = u_offsets;
  }

  // cal style mapping

  v_color = a_Color;
  v_radius = newSize;

  // anti-alias
  //  float antialiased_blur = -max(u_blur, antialiasblur);
  float antialiasblur = -max(2.0 / u_DevicePixelRatio / a_Size, u_blur);

  vec2 offset = (extrude.xy * (newSize + u_stroke_width) + textrueOffsets);
  vec3 aPosition = a_Position;
  if(u_isMeter < 1.0) {
    // 不以米为实际单位
    offset = project_pixel(offset);
  } else {
    // 以米为实际单位
    antialiasblur *= pow(19.0 - u_Zoom, 2.0);
    antialiasblur = max(antialiasblur, -0.01);
    // offset *= 0.5;

    if(u_CoordinateSystem == COORDINATE_SYSTEM_LNGLAT || u_CoordinateSystem == COORDINATE_SYSTEM_LNGLAT_OFFSET) {
      aPosition.xy += offset;
      offset.x = 0.0;
      offset.y = 0.0;
    }
  }

  v_data = vec4(extrude.x, extrude.y, antialiasblur,shape_type);

  vec4 project_pos = project_position(vec4(aPosition.xy, 0.0, 1.0));

  if(u_CoordinateSystem == COORDINATE_SYSTEM_LNGLAT || u_CoordinateSystem == COORDINATE_SYSTEM_LNGLAT_OFFSET) {
    float mapboxZoomScale = 4.0/pow(2.0, 21.0 - u_Zoom);
  }

if(u_coord > 0.0) {
  if(u_CoordinateSystem == COORDINATE_SYSTEM_P20_2) { // gaode2.x
    gl_Position = u_Mvp * vec4(project_pos.xy + offset, 0.0, 1.0);
  } else {
    gl_Position = project_common_position_to_clipspace(vec4(project_pos.xy + offset, 0.0, 1.0));
  }
} else {
  gl_PointSize = 24.0;
  vec2 pointPos = a_Position.xy;
  vec4 world = vec4(project_mvt_offset_position(vec4(u_tileOrigin, 0.0, 1.0)).xyz, 1.0); // 瓦片起始点的世界坐标

  vec2 pointOffset =  pointPos *  pow(2.0, u_Zoom); // 瓦片内的点的偏移坐标
  
  world.xy += offset;
  world.xy += pointOffset;

  if (u_CoordinateSystem == COORDINATE_SYSTEM_METER_OFFSET || u_CoordinateSystem == COORDINATE_SYSTEM_LNGLAT_OFFSET) {
    // Needs to be divided with project_uCommonUnitsPerMeter
    world.w *= u_PixelsPerMeter.z;
  }

  gl_Position = u_ViewProjectionMatrix * world + u_ViewportCenterProjection;
}

 
  setPickingColor(a_PickingColor);


}