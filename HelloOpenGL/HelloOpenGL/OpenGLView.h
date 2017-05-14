//
//  OpenGLView.h
//  HelloOpenGL
//
//  Created by yanwu wei on 2017/5/2.
//  Copyright © 2017年 Ivan. All rights reserved.
//

//引入OpenGL的Header，创建一些后面会用到的实例变量。


#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#include <OpenGLES/ES2/gl.h>
#include <OpenGLES/ES2/glext.h>

@interface OpenGLView : UIView
{
    CAEAGLLayer* _eaglLayer;
    EAGLContext* _context;
    GLuint _colorRenderBuffer;
    
    GLuint _positionSlot;
    GLuint _colorSlot;
    
    GLuint _projectionUniform;
    GLuint _modelViewUniform;
    
    float _currentRotation;
    
    GLuint _depthRenderBuffer;
    
}

@end
