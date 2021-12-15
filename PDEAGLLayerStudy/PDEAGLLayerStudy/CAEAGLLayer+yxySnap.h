//
//  CAEAGLLayer+yxySnap.h
//  PDEAGLLayerStudy
//
//  Created by xingye yang on 2021/12/15.
//  Copyright © 2021 彭懂. All rights reserved.
//

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>
#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface CAEAGLLayer (yxySnap)
- (UIImage *)snapshotOpenGLView:(UIView*)view viewRenderbuffer:(GLint)viewRenderbuffer;
@end

NS_ASSUME_NONNULL_END
