//
//  ViewController.m
//  PDEAGLLayerStudy
//
//  Created by 彭懂 on 16/8/18.
//  Copyright © 2016年 彭懂. All rights reserved.
//

/**
 *  CAEAGLLayer
 
 当iOS要处理高性能图形绘制，必要时就是OpenGL。应该说它应该是最后的杀手锏，至少对于非游戏的应用来说是的。因为相比Core Animation和UIkit框架，它不可思议地复杂。
 
 OpenGL提供了Core Animation的基础，它是底层的C接口，直接和iPhone，iPad的硬件通信，极少地抽象出来的方法。OpenGL没有对象或是图层的继承概念。它只是简单地处理三角形。OpenGL中所有东西都是3D空间中有颜色和纹理的三角形。用起来非常复杂和强大，但是用OpenGL绘制iOS用户界面就需要很多很多的工作了。
 
 为了能够以高性能使用Core Animation，你需要判断你需要绘制哪种内容（矢量图形，例子，文本，等等），但后选择合适的图层去呈现这些内容，Core Animation中只有一些类型的内容是被高度优化的；所以如果你想绘制的东西并不能找到标准的图层类，想要得到高性能就比较费事情了。
 
 因为OpenGL根本不会对你的内容进行假设，它能够绘制得相当快。利用OpenGL，你可以绘制任何你知道必要的集合信息和形状逻辑的内容。所以很多游戏都喜欢用OpenGL（这些情况下，Core Animation的限制就明显了：它优化过的内容类型并不一定能满足需求），但是这样依赖，方便的高度抽象接口就没了。
 
 在iOS 5中，苹果引入了一个新的框架叫做GLKit，它去掉了一些设置OpenGL的复杂性，提供了一个叫做CLKView的UIView的子类，帮你处理大部分的设置和绘制工作。前提是各种各样的OpenGL绘图缓冲的底层可配置项仍然需要你用CAEAGLLayer完成，它是CALayer的一个子类，用来显示任意的OpenGL图形。
 
 大部分情况下你都不需要手动设置CAEAGLLayer（假设用GLKView），过去的日子就不要再提了。特别的，我们将设置一个OpenGL ES 2.0的上下文，它是现代的iOS设备的标准做法。
 
 尽管不需要GLKit也可以做到这一切，但是GLKit囊括了很多额外的工作，比如设置顶点和片段着色器，这些都以类C语言叫做GLSL自包含在程序中，同时在运行时载入到图形硬件中。编写GLSL代码和设置EAGLayer没有什么关系，所以我们将用GLKBaseEffect类将着色逻辑抽象出来。其他的事情，我们还是会有以往的方式。
 
 在开始之前，你需要将GLKit和OpenGLES框架加入到你的项目中，然后就可以实现清单6.14中的代码，里面是设置一个GAEAGLLayer的最少工作，它使用了OpenGL ES 2.0 的绘图上下文，并渲染了一个有色三角
 */

#import "ViewController.h"
#import <GLKit/GLKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import "CAEAGLLayer+yxySnap.h"
#import "UIView+yxySnap.h"

@interface ViewController ()
{
    GLint viewRenderbuffer;
}
@property (nonatomic, strong) UIView *glView;
@property (nonatomic, strong) EAGLContext *glContext;
@property (nonatomic, strong) CAEAGLLayer *glLayer;
@property (nonatomic, assign) GLuint frameBuffer;
@property (nonatomic, assign) GLuint colorRenderBuffer;
@property (nonatomic, assign) GLint frameBufferWidth;
@property (nonatomic, assign) GLint frameBufferHeight;
@property (nonatomic, strong) GLKBaseEffect *effect;

@property(nonatomic,strong)UIImageView *imgview;
@property(nonatomic,strong)UIButton *button;

@end

@implementation ViewController

- (void)dealloc
{
    [self tearDownBuffers];
    [EAGLContext setCurrentContext:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UIView *grayView = [[UIView alloc] initWithFrame:CGRectMake(100, 100, 200, 200)];
    grayView.backgroundColor = [UIColor grayColor];
    self.glView = grayView;
    [self.view addSubview:grayView];
    
    self.glContext = [[EAGLContext alloc] initWithAPI: kEAGLRenderingAPIOpenGLES2];
    [EAGLContext setCurrentContext:self.glContext];
    
    //set up layer
    self.glLayer = [CAEAGLLayer layer];
    self.glLayer.frame = self.glView.bounds;
    [self.glView.layer addSublayer:self.glLayer];
    
    self.glLayer.drawableProperties = @{kEAGLDrawablePropertyRetainedBacking:@YES, kEAGLDrawablePropertyColorFormat: kEAGLColorFormatRGBA8};
    
    
    //set up base effect
    self.effect = [[GLKBaseEffect alloc] init];
    
    //set up buffers
    [self setUpBuffers];
    
    //draw frame
    [self drawFrame];
    
    _imgview = [[UIImageView alloc] initWithFrame:CGRectMake(0, 300, 300, 300)];
    [self.view addSubview:_imgview];
    _imgview.backgroundColor = [UIColor redColor];
    _button = [UIButton buttonWithType:UIButtonTypeCustom];
    _button.frame = CGRectMake(200, 300, 100, 50);
    [_button setTitle:@"button" forState:UIControlStateNormal];
    [self.view addSubview:_button];
    [_button addTarget:self action:@selector(click) forControlEvents:UIControlEventTouchUpInside];
}

-(void)click
{
    UIImage *img =  [self.view snapshotOpenGLView:self.view viewRenderbuffer:_frameBuffer];
    _imgview.image = img;
}

- (UIImage *)snapshotOpenGLView:(UIView*)view viewRenderbuffer:(GLint)viewRenderbuffer
{
    GLint backingWidth , backingHeight ;
    // Bind the color renderbuffer used to render the OpenGL ES view
    // If your application only creates a single color renderbuffer which is already bound at this point,
    
    // this call is redundant, but it is needed if you're dealing with multiple renderbuffers.
    
    // Note, replace "viewRenderbuffer" with the actual name of the renderbuffer object defined in your class.
    
//    glBindRenderbufferOES(GL_RENDERBUFFER_OES, viewRenderbuffer);
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, (GLuint)viewRenderbuffer);
    
    // Get the size of the backing CAEAGLLayer
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
    glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
    
    NSInteger x = 0, y = 0, width = backingWidth, height = backingHeight;
    NSInteger dataLength = width * height * 4;
    
    GLubyte *data = (GLubyte*)malloc(dataLength * sizeof(GLubyte));
    
    // Read pixel data from the framebuffer
    
//    glPixelStorei(GL_PACK_ALIGNMENT, 4);
    glViewport(0, 0, (GLsizei)(width), (GLsizei)(height));
    
    glReadPixels(x, y, width, height, GL_RGBA, GL_UNSIGNED_BYTE, data);
    
    glBindFramebufferOES(GL_FRAMEBUFFER_OES, (GLuint)viewRenderbuffer);
    glViewport(0, 0, (GLsizei)(width), (GLsizei)(height));
    
    // Create a CGImage with the pixel data
    
    // If your OpenGL ES content is opaque, use kCGImageAlphaNoneSkipLast to ignore the alpha channel
    
    // otherwise, use kCGImageAlphaPremultipliedLast
    
    CGDataProviderRef ref = CGDataProviderCreateWithData(NULL, data, dataLength, NULL);
    
    CGColorSpaceRef colorspace = CGColorSpaceCreateDeviceRGB();
    
    CGImageRef iref = CGImageCreate(width, height, 8, 32, width * 4, colorspace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast,ref, NULL, true, kCGRenderingIntentDefault);
    
    // OpenGL ES measures data in PIXELS
    
    // Create a graphics context with the target size measured in POINTS
    
    NSInteger widthInPoints, heightInPoints;
    
    if (NULL != &UIGraphicsBeginImageContextWithOptions) {
        
        // On iOS 4 and later, use UIGraphicsBeginImageContextWithOptions to take the scale into consideration
        
        // Set the scale parameter to your OpenGL ES view's contentScaleFactor
        
        // so that you get a high-resolution snapshot when its value is greater than 1.0
        
        CGFloat scale = view.contentScaleFactor;
        
        widthInPoints = width / scale;
        
        heightInPoints = height / scale;
        
        UIGraphicsBeginImageContextWithOptions(CGSizeMake(widthInPoints, heightInPoints), NO, scale);
    }
    
    else {
        // On iOS prior to 4, fall back to use UIGraphicsBeginImageContext
        widthInPoints = width;
        heightInPoints = height;
        UIGraphicsBeginImageContext(CGSizeMake(widthInPoints, heightInPoints));
    }
    
    CGContextRef cgcontext = UIGraphicsGetCurrentContext();
    
    // UIKit coordinate system is upside down to GL/Quartz coordinate system
    
    // Flip the CGImage by rendering it to the flipped bitmap context
    
    // The size of the destination area is measured in POINTS
    
    CGContextSetBlendMode(cgcontext, kCGBlendModeCopy);
    CGContextDrawImage(cgcontext, CGRectMake(0.0, 0.0, widthInPoints, heightInPoints), iref);
    // Retrieve the UIImage from the current context
    
    CGImageRef imageMasked = CGBitmapContextCreateImage(cgcontext);
    UIImage * image = [UIImage imageWithCGImage:imageMasked scale:view.contentScaleFactor orientation:UIImageOrientationUp];
    UIGraphicsEndImageContext();
    
    // Clean up
    
    free(data);
    CFRelease(ref);
    CFRelease(colorspace);
    CGImageRelease(iref);
    return image;
}


- (void)setUpBuffers {
    
    // 设置尺寸缓冲
    glGenFramebuffers(1, &_frameBuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    
    // 设置颜色缓冲
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, _colorRenderBuffer);
    [self.glContext renderbufferStorage:GL_RENDERBUFFER fromDrawable:self.glLayer];
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_frameBufferWidth);
    glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &_frameBufferHeight);
    
    // 检测是否成功
    if (glCheckFramebufferStatus(GL_FRAMEBUFFER) != GL_FRAMEBUFFER_COMPLETE) {
        NSLog(@"Faild to make complite frameBuffer object  %i", glCheckFramebufferStatus(GL_FRAMEBUFFER));
    }
}

- (void)tearDownBuffers
{
    if (_frameBuffer) {
        //delete framebuffer
        glDeleteFramebuffers(1, &_frameBuffer);
        _frameBuffer = 0;
    }
    
    if (_colorRenderBuffer) {
        //delete color render buffer
        glDeleteRenderbuffers(1, &_colorRenderBuffer);
        _colorRenderBuffer = 0;
    }
}

- (void)drawFrame {
    //bind framebuffer & set viewport
    glBindFramebuffer(GL_FRAMEBUFFER, _frameBuffer);
    glViewport(0, 0, _frameBufferWidth, _frameBufferHeight);
    
    //bind shader program
    [self.effect prepareToDraw];
    
    //clear the screen
    glClear(GL_COLOR_BUFFER_BIT); glClearColor(0.0, 0.0, 0.0, 1.0);
    
    //set up vertices
    GLfloat vertices[] = {
        -0.5f, -0.5f, -1.0f, 0.0f, 0.5f, -1.0f, 0.5f, -0.5f, -1.0f,
    };
    
    //set up colors
    GLfloat colors[] = {
        0.0f, 0.0f, 1.0f, 1.0f, 0.0f, 1.0f, 0.0f, 1.0f, 1.0f, 0.0f, 0.0f, 1.0f,
    };
    
    //draw triangle
    glEnableVertexAttribArray(GLKVertexAttribPosition);
    glEnableVertexAttribArray(GLKVertexAttribColor);
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, 0, vertices);
    glVertexAttribPointer(GLKVertexAttribColor,4, GL_FLOAT, GL_FALSE, 0, colors);
    glDrawArrays(GL_TRIANGLES, 0, 3);
    
    //present render buffer
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [self.glContext presentRenderbuffer:GL_RENDERBUFFER];
}


@end
