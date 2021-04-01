#include <metal_stdlib>
using namespace metal;

kernel void hypot_kernel(const texture2d<float, access::read> x [[texture(0)]],
                         const texture2d<float, access::read> y [[texture(1)]],
                         texture2d<float, access::write> output [[texture(2)]],
                         uint2 indexes [[thread_position_in_grid]]){
    auto x_value = x.read(indexes);
    auto y_value = y.read(indexes);
    auto value = sqrt(x_value * x_value + y_value * y_value);
    output.write(value, indexes);
}

kernel void scale_kernel(const texture2d<float, access::read> input [[texture(0)]],
                         const texture2d<float, access::read> minMax [[texture(1)]],
                         texture2d<float, access::write> output [[texture(2)]],
                         uint2 indexes [[thread_position_in_grid]]){
    uint2 maxIndex = {1, 0};
    auto maxValue = minMax.read(maxIndex);
    auto inputValue = input.read(indexes);
    output.write(inputValue / maxValue, indexes);
}

kernel void atan2_kernel(const texture2d<float, access::read> x [[texture(0)]],
                         const texture2d<float, access::read> y [[texture(1)]],
                         const texture2d<float, access::write> output [[texture(2)]],
                         uint2 indexes [[thread_position_in_grid]]){
    auto angle = atan2(x.read(indexes), y.read(indexes));
    output.write(angle.x < 0.0f ? angle + M_PI_F : angle, indexes);
}

kernel void non_max_suppression_kernel(const texture2d<float, access::read> magnitude [[texture(0)]],
                                const texture2d<float, access::read> theta [[texture(1)]],
                                texture2d<float, access::write> output [[texture(2)]],
                                uint2 indexes [[thread_position_in_grid]]){
    float4 n1, n2;
    const auto value = magnitude.read(indexes);
    const auto angle = theta.read(indexes);
    
    if (indexes.x == 0 || indexes.x == magnitude.get_width() - 1 || indexes.y == 0 || indexes.y == magnitude.get_height() - 1){
        output.write(float4(0.0f), indexes);
        return;
    }
    
    if ((angle.x >= 0 && angle.x < M_PI_F / 8.0f) || (angle.x >= 7.0f / 8.0f * M_PI_F && angle.x <= M_PI_F)){
        n1 = magnitude.read((uint2){indexes.x - 1, indexes.y});
        n2 = magnitude.read((uint2){indexes.x + 1, indexes.y});
    } else if(angle.x >= M_PI_F / 8.0f && angle.x < 3.0f / 8.0f * M_PI_F){
        n1 = magnitude.read((uint2){indexes.x - 1, indexes.y + 1});
        n2 = magnitude.read((uint2){indexes.x + 1, indexes.y - 1});
    } else if(angle.x >= 3.0f / 8.0f * M_PI_F && angle.x < 5.0f / 8.0f * M_PI_F){
        n1 = magnitude.read((uint2){indexes.x, indexes.y + 1});
        n2 = magnitude.read((uint2){indexes.x, indexes.y - 1});
    } else{
        n1 = magnitude.read((uint2){indexes.x + 1, indexes.y + 1});
        n2 = magnitude.read((uint2){indexes.x - 1, indexes.y - 1});
    }
    
    const auto outputValue = value.x >= n1.x && value.x >= n2.x ? value : float4(0.0f);
    output.write(outputValue, indexes);
}

kernel void threshold_kernel(const texture2d<float, access::read> input [[texture(0)]],
                      const texture2d<float, access::read> min_max [[texture(1)]],
                      const texture2d<float, access::write> output [[texture(2)]],
                      constant float* thresholds [[buffer(0)]],
                      constant float* min_max_pixels [[buffer(1)]],
                      uint2 indexes [[thread_position_in_grid]]){
    const auto max_value = min_max.read((uint2){1, 0});
    const auto high_threshold = max_value.x * thresholds[0];
    const auto low_threshold = high_threshold * thresholds[1];
    const auto value = input.read(indexes);
    float4 outputValue;
    
    if(value.x >= high_threshold){
        outputValue = float4(min_max_pixels[1], 0.0f, 0.0f, 0.0f);
    }else if(value.x >= low_threshold && value.x < high_threshold){
        outputValue = float4(min_max_pixels[0], 0.0f, 0.0f, 0.0f);
    }else{
        outputValue = float4(0.0f);
    }
    output.write(outputValue, indexes);
}


kernel void hysteresis_kernel(const texture2d<float, access::read> input [[texture(0)]],
                       texture2d<float, access::write> output [[texture(1)]],
                       constant float* min_max_pixels [[buffer(0)]],
                       uint2 indexes [[thread_position_in_grid]]){
    const auto value = input.read(indexes);
    const auto min_pixel = min_max_pixels[0];
    const auto max_pixel = min_max_pixels[1];
    
    if(value.x == min_pixel && indexes.x >= 1 && indexes.x <= input.get_width() - 1 && indexes.y >= 1 && indexes.y <= input.get_height() - 1){
        for(int row = -1; row <= 1; row++){
            for(int column = -1; column <= 1; column++){
                if(row == 0 && column == 0) continue;
                const auto neighbor_index = uint2{indexes.x + column, indexes.y + row};
                const auto neighbor_value = input.read(neighbor_index);
                if(neighbor_value.x == max_pixel){
                    output.write(float4(max_pixel, 0.0f, 0.0f, 0.0f), indexes);
                    return;
                }
            }
        }
    }
    output.write(float4(0.0f), indexes);
}
