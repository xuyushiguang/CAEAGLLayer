//
//  UIView+yxySnap.h
//  PDEAGLLayerStudy
//
//  Created by xingye yang on 2021/12/15.
//  Copyright © 2021 彭懂. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

NS_ASSUME_NONNULL_BEGIN

@interface UIView (yxySnap)

- (UIImage *)snapshotOpenGLView:(UIView*)view viewRenderbuffer:(GLint)viewRenderbuffer;

-(UIImage *) glToUIImage;

@end

NS_ASSUME_NONNULL_END
