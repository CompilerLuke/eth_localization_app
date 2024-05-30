// https://raw.githubusercontent.com/pytorch/ios-demo-app/master/PyTorchDemo/PyTorchDemo/TorchBridge/TorchModule.mm

#import "TorchModule.h"
#import <LibTorch/LibTorch.h>


@implementation TorchModule {
 @protected
  torch::jit::script::Module _impl;
}

- (nullable instancetype)initWithFileAtPath:(NSString*)filePath {
  self = [super init];
  if (self) {
    //try {
      auto qengines = at::globalContext().supportedQEngines();
      if (std::find(qengines.begin(), qengines.end(), at::QEngine::QNNPACK) != qengines.end()) {
        at::globalContext().setQEngine(at::QEngine::QNNPACK);
      }
      _impl = torch::jit::load(filePath.UTF8String);
      //_impl.to("metal");
      _impl.eval();
    /*} catch (const std::exception& exception) {
      NSLog(@"%s", exception.what());
      return nil;
    }*/
  }
  return self;
}

@end

NSData *getImageBuffer(UIImage *image) {
    // Convert UIImage to PNG data
    NSData *imageData = UIImagePNGRepresentation(image);
    if (!imageData) {
        NSLog(@"Failed to convert UIImage to PNG data");
        return nil;
    }
    return imageData;
}

@implementation LocalizationModule

- (NSArray<NSArray<NSNumber*>*>*)localizeImage:(const float*)image width:(int)width height:(int)height intrinsics:(const float*)intrinsics {
  try {
    at::Tensor tensor = torch::from_blob((float*)image, {height, width, 3}, at::kFloat);
    at::Tensor tensor_intrinsics = torch::from_blob((float*)intrinsics, {4}, at::kFloat);
    tensor = tensor.transpose(0,1);
    torch::autograd::AutoGradMode guard(false);
    c10::InferenceMode mode(true);
    auto outputTensor = _impl.forward({tensor, tensor_intrinsics}).toTensor();
    float* floatBuffer = outputTensor.data_ptr<float>();
    if (!floatBuffer) {
      return nil;
    }
    
    int num_pred = outputTensor.sizes()[0];
    int dim = outputTensor.size(1);
      
    NSMutableArray<NSMutableArray<NSNumber*>*>* results = [[NSMutableArray alloc] init];
    for(int i = 0; i < num_pred; i++) {
        NSMutableArray<NSNumber*> *pred = [[NSMutableArray alloc] init];
        for (int j = 0; j < dim; j++) {
            [pred addObject:@(floatBuffer[i*dim + j])];
        }
        [results addObject:pred];
    }
    return [results copy];
  } catch (const std::exception& exception) {
    NSLog(@"%s", exception.what());
  }
  return nil;
}

@end


