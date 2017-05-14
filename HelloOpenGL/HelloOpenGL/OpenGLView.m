//
//  OpenGLView.m
//  HelloOpenGL
//
//  Created by yanwu wei on 2017/5/2.
//  Copyright © 2017年 Ivan. All rights reserved.
//


//http://blog.csdn.net/pizi0475/article/details/7286293

#import "OpenGLView.h"
#import "CC3GLMatrix.h" 

//　　这段代码的作用是：
//　　1 一个用于跟踪所有顶点信息的结构Vertex （目前只包含位置和颜色。）
//　　2 定义了以上面这个Vertex结构为类型的array。
//　　3 一个用于表示三角形顶点的数组。
//　　数据准备好了，我们来开始把数据传入OpenGL


typedef struct {
    float Position[3];
    float Color[4];
} Vertex;

//// Revert vertices back to z-value 0
//const Vertex Vertices[] = {
//    {{1, -1, 0}, {1, 0, 0, 1}},
//    {{1, 1, 0}, {0, 1, 0, 1}},
//    {{-1, 1, 0}, {0, 0, 1, 1}},
//    {{-1, -1, 0}, {0, 0, 0, 1}}
//};
//
//const GLubyte Indices[] = {
//    0, 1, 2,
//    2, 3, 0
//};

const Vertex Vertices[] = {
    {{1, -1, 0}, {1, 0, 0, 1}},
    {{1, 1, 0}, {1, 0, 0, 1}},
    {{-1, 1, 0}, {0, 1, 0, 1}},
    {{-1, -1, 0}, {0, 1, 0, 1}},
    {{1, -1, -1}, {1, 0, 0, 1}},
    {{1, 1, -1}, {1, 0, 0, 1}},
    {{-1, 1, -1}, {0, 1, 0, 1}},
    {{-1, -1, -1}, {0, 1, 0, 1}}
};

const GLubyte Indices[] = {
    // Front
    0, 1, 2,
    2, 3, 0,
    // Back
    4, 6, 5,
    4, 7, 6,
    // Left
    2, 7, 3,
    7, 6, 2,
    // Right
    0, 4, 1,
    4, 1, 5,
    // Top
    6, 2, 1,
    1, 6, 5,
    // Bottom
    0, 3, 7,
    0, 7, 4     
};

@implementation OpenGLView

//设置layer class 为 CAEAGLLayer
//想要显示OpenGL的内容，你需要把它缺省的layer设置为一个特殊的layer。
//（CAEAGLLayer）。这里通过直接复写layerClass的方法。
+ (Class)layerClass
{
    return [CAEAGLLayer class];
}



//4) 设置layer为不透明（Opaque）
//因为缺省的话，CALayer是透明的。而透明的层对性能负荷很大，特别是OpenGL的层。
//（如果可能，尽量都把层设置为不透明。
//另一个比较明显的例子是自定义tableview cell）
- (void)setupLayer
{
    _eaglLayer = (CAEAGLLayer*) self.layer;
    _eaglLayer.opaque = YES;
}

//5）创建OpenGL context

//无论你要OpenGL帮你实现什么，总需要这个 EAGLContext。
//EAGLContext管理所有通过OpenGL进行draw的信息。
//这个与Core Graphics context类似。
//当你创建一个context，你要声明你要用哪个version的API。
//这里，我们选择OpenGL ES 2.0.
//（容错处理，如果创建失败了，我们的程序会退出）

- (void)setupContext
{
    EAGLRenderingAPI api = kEAGLRenderingAPIOpenGLES2;
    _context = [[EAGLContext alloc] initWithAPI:api];
    if (!_context)
    {
        NSLog(@"Failed to initialize OpenGLES 2.0 context");
        exit(1);
    }
    
    if (![EAGLContext setCurrentContext:_context])
    {
        NSLog(@"Failed to set current OpenGL context");
        exit(1);
    }
}

//6）创建render buffer （渲染缓冲区）

//Render buffer 是OpenGL的一个对象，用于存放渲染过的图像。
//有时候你会发现render buffer会作为一个color buffer被引用，
//因为本质上它就是存放用于显示的颜色。
//创建render buffer的三步：
//1.     调用glGenRenderbuffers来创建一个新的render buffer object。
//这里返回一个唯一的integer来标记render buffer
//（这里把这个唯一值赋值到_colorRenderBuffer）。
//有时候你会发现这个唯一值被用来作为程序内的一个OpenGL 的名称。
//（反正它唯一嘛）
//2.     调用glBindRenderbuffer ，告诉这个OpenGL：
//我在后面引用GL_RENDERBUFFER的地方，
//其实是想用_colorRenderBuffer。其实就是告诉OpenGL，
//我们定义的buffer对象是属于哪一种OpenGL对象
//3.     最后，为render buffer分配空间。renderbufferStorage

- (void)setupRenderBuffer
{
    glGenRenderbuffers(1, &_colorRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _colorRenderBuffer);
    [_context renderbufferStorage:GL_RENDERBUFFER fromDrawable:_eaglLayer];
}


//7）创建一个 frame buffer （帧缓冲区）

//Frame buffer也是OpenGL的对象，它包含了前面提到的render buffer，
//以及其它后面会讲到的诸如：
//depth buffer、stencil buffer 和 accumulation buffer。
//前两步创建frame buffer的动作跟创建render buffer的动作很类似。
//（反正也是用一个glBind什么的）
//而最后一步  glFramebufferRenderbuffer 这个才有点新意。
//它让你把前面创建的buffer render依附在frame buffer的GL_COLOR_ATTACHMENT0位置上。

- (void)setupFrameBuffer
{
    GLuint framebuffer;
    glGenFramebuffers(1, &framebuffer);
    glBindFramebuffer(GL_FRAMEBUFFER, framebuffer);
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0,
                              GL_RENDERBUFFER, _colorRenderBuffer);
    
    glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT,
                              GL_RENDERBUFFER, _depthRenderBuffer);
 
    
}

//8）清理屏幕

//为了尽快在屏幕上显示一些什么，在我们和那些 vertexes、shaders打交道之前，
//把屏幕清理一下，显示另一个颜色吧。（RGB 0, 104, 55，绿色吧）
//这里每个RGB色的范围是0~1，所以每个要除一下255.
//下面解析一下每一步动作：
//1.      调用glClearColor ，设置一个RGB颜色和透明度，
//接下来会用这个颜色涂满全屏。
//2.      调用glClear来进行这个“填色”的动作（大概就是photoshop那个油桶嘛）。
//还记得前面说过有很多buffer的话，这里我们要用到GL_COLOR_BUFFER_BIT来声明要清理哪一个缓冲区。
//3.      调用OpenGL context的presentRenderbuffer方法，
//把缓冲区（render buffer和color buffer）的颜色呈现到UIView上。

//- (void)render
//{
//    glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0);
//    glClear(GL_COLOR_BUFFER_BIT);
//    [_context presentRenderbuffer:GL_RENDERBUFFER];
//}


//9）把前面的动作串起来修改一下OpenGLView.m
// Replace initWithFrame with this
- (id)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self)
    {
        [self setupLayer];
        [self setupContext];
        [self setupDepthBuffer];
        [self setupRenderBuffer];
        [self setupFrameBuffer];
        
        [self compileShaders];
        [self setupVBOs];
        [self setupDisplayLink];
    }
    return self;
}

//下面解析：
//1 这是一个UIKit编程的标准用法，就是在NSBundle中查找某个文件。
//大家应该熟悉了吧。
//2 调用 glCreateShader来创建一个代表shader 的OpenGL对象。
//这时你必须告诉OpenGL，你想创建 fragment shader还是vertex shader。
//所以便有了这个参数：shaderType
//3 调用glShaderSource ，让OpenGL获取到这个shader的源代码。
//（就是我们写的那个）这里我们还把NSString转换成C-string
//4 最后，调用glCompileShader 在运行时编译shader
//5 大家都是程序员，有程序的地方就会有fail。有程序员的地方必然会有debug。
//如果编译失败了，我们必须一些信息来找出问题原因。
//glGetShaderiv 和 glGetShaderInfoLog  会把error信息输出到屏幕。（然后退出）

- (GLuint)compileShader:(NSString*)shaderName withType:(GLenum)shaderType
{
    
    // 1
    NSString* shaderPath = [[NSBundle mainBundle] pathForResource:shaderName
                                                           ofType:@"glsl"];
    NSError* error;
    NSString* shaderString = [NSString stringWithContentsOfFile:shaderPath
                                                       encoding:NSUTF8StringEncoding error:&error];
    if (!shaderString) {
        NSLog(@"Error loading shader: %@", error.localizedDescription);
        exit(1);
    }
    
    // 2
    GLuint shaderHandle = glCreateShader(shaderType);
    
    // 3
    const char* shaderStringUTF8 = [shaderString UTF8String];
    int shaderStringLength = (int)[shaderString length];
    glShaderSource(shaderHandle, 1, &shaderStringUTF8, &shaderStringLength);
    
    // 4
    glCompileShader(shaderHandle);
    
    // 5
    GLint compileSuccess;
    glGetShaderiv(shaderHandle, GL_COMPILE_STATUS, &compileSuccess);
    if (compileSuccess == GL_FALSE) {
        GLchar messages[256];
        glGetShaderInfoLog(shaderHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString); 
        exit(1); 
    } 
    
    return shaderHandle; 
    
}

//我们还需要一些步骤来编译vertex shader 和frament shader。
//- 把它们俩关联起来
//- 告诉OpenGL来调用这个程序，还需要一些指针什么的。
//在compileShader: 方法下方，加入这些代码


//下面是解析：
//　　1       用来调用你刚刚写的动态编译方法，
//分别编译了vertex shader 和 fragment shader
//　　2       调用了glCreateProgram glAttachShader  glLinkProgram
//连接 vertex 和 fragment shader成一个完整的program。
//　　3       调用 glGetProgramiv
// glGetProgramInfoLog 来检查是否有error，并输出信息。
//　　4       调用 glUseProgram
//让OpenGL真正执行你的program
//　　5       最后，调用 glGetAttribLocation
//来获取指向 vertex shader传入变量的指针。以后就可以通过这写指针来使用了。
//还有调用 glEnableVertexAttribArray来启用这些数据。（因为默认是 disabled的。）
//　　最后还有两步：
//　　1 在 initWithFrame方法里，在调用render之前要加入这个：


- (void)compileShaders
{
    
    // 1
    GLuint vertexShader = [self compileShader:@"SimpleVertex"
                                     withType:GL_VERTEX_SHADER];
    GLuint fragmentShader = [self compileShader:@"SimpleFragment"
                                       withType:GL_FRAGMENT_SHADER];
    
    // 2
    GLuint programHandle = glCreateProgram();
    glAttachShader(programHandle, vertexShader);
    glAttachShader(programHandle, fragmentShader);
    glLinkProgram(programHandle);
    
    // 3
    GLint linkSuccess;
    glGetProgramiv(programHandle, GL_LINK_STATUS, &linkSuccess);
    if (linkSuccess == GL_FALSE)
    {
        GLchar messages[256];
        glGetProgramInfoLog(programHandle, sizeof(messages), 0, &messages[0]);
        NSString *messageString = [NSString stringWithUTF8String:messages];
        NSLog(@"%@", messageString);
        exit(1);
    }
    
    // 4
    glUseProgram(programHandle);
    
    // 5
    _positionSlot = glGetAttribLocation(programHandle, "Position");
    _colorSlot = glGetAttribLocation(programHandle, "SourceColor");
    glEnableVertexAttribArray(_positionSlot);
    glEnableVertexAttribArray(_colorSlot);
    
    
    // Add to bottom of compileShaders
    _projectionUniform = glGetUniformLocation(programHandle, "Projection");
    

    // Add to end of compileShaders
    _modelViewUniform = glGetUniformLocation(programHandle, "Modelview");

} 

//传数据到OpenGL的话，最好的方式就是用Vertex Buffer对象。
//　　基本上，它们就是用于缓存顶点数据的OpenGL对象。
//通过调用一些function来把数据发送到OpenGL-land。（是指OpenGL的画面？）
//这里有两种顶点缓存类型– 一种是用于跟踪每个顶点信息的（正如我们的Vertices array）
//，另一种是用于跟踪组成每个三角形的索引信息（我们的Indices array）。
//　　下面我们在initWithFrame中，加入一些代码：

//
//如你所见，其实很简单的。这其实是一种之前也用过的模式（pattern）。
//　　glGenBuffers - 创建一个Vertex Buffer 对象
//glBindBuffer – 告诉OpenGL我们的vertexBuffer 是指GL_ARRAY_BUFFER
//　　glBufferData – 把数据传到OpenGL-land
//　　想起哪里用过这个模式吗？要不再回去看看frame buffer那一段？
//　　万事俱备，我们可以通过新的shader，用新的渲染方法来把顶点数据画到屏幕上。



- (void)setupVBOs {
    
    GLuint vertexBuffer;
    glGenBuffers(1, &vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    GLuint indexBuffer;
    glGenBuffers(1, &indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
    
}


//　　用这段代码替换掉之前的render：

//　　1       调用glViewport 设置UIView中用于渲染的部分。这个例子中指定了整个屏幕。
//但如果你希望用更小的部分，你可以更变这些参数。
//　　2       调用glVertexAttribPointer来为vertex shader的两个输入参数配置两个合适的值。
//　　第二段这里，是一个很重要的方法，让我们来认真地看看它是如何工作的：
//　　·第一个参数，声明这个属性的名称，之前我们称之为glGetAttribLocation
//　　·第二个参数，定义这个属性由多少个值组成。譬如说position是由3个float（x,y,z）组成，
//而颜色是4个float（r,g,b,a）
//　　·第三个，声明每一个值是什么类型。（这例子中无论是位置还是颜色，我们都用了GL_FLOAT）
//　　·第四个，嗯……它总是false就好了。
//　　·第五个，指 stride 的大小。这是一个种描述每个 vertex数据大小的方式。
//所以我们可以简单地传入 sizeof（Vertex），让编译器计算出来就好。
//　　·最后一个，是这个数据结构的偏移量。表示在这个结构中，从哪里开始获取我们的值。
//Position的值在前面，所以传0进去就可以了。而颜色是紧接着位置的数据，
//而position的大小是3个float的大小，所以是从 3 * sizeof(float) 开始的。
//　　回来继续说代码，第三点：
//　3       调用glDrawElements ，它最后会在每个vertex上调用我们的vertex shader，
//以及每个像素调用fragment shader，最终画出我们的矩形。
//　　它也是一个重要的方法，我们来仔细研究一下：
//　　·第一个参数，声明用哪种特性来渲染图形。有GL_LINE_STRIP 和 GL_TRIANGLE_FAN。
//然而GL_TRIANGLE是最常用的，特别是与VBO 关联的时候。
//　　·第二个，告诉渲染器有多少个图形要渲染。我们用到C的代码来计算出有多少个。
//这里是通过个 array的byte大小除以一个Indice类型的大小得到的。
//　　·第三个，指每个indices中的index类型
//　　·最后一个，在官方文档中说，它是一个指向index的指针。但在这里，
//我们用的是VBO，所以通过index的array就可以访问到了
//（在GL_ELEMENT_ARRAY_BUFFER传过了），所以这里不需要.


// Add new method right after setupRenderBuffer
- (void)setupDepthBuffer {
    glGenRenderbuffers(1, &_depthRenderBuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, _depthRenderBuffer);
    glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, self.frame.size.width, self.frame.size.height);
}

- (void)render:(CADisplayLink*)displayLink {
    glClearColor(0, 104.0/255.0, 55.0/255.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glEnable(GL_DEPTH_TEST);
 
    // Add to render, right before the call to glViewport
    CC3GLMatrix *projection = [CC3GLMatrix matrix];
    float h =4.0f* self.frame.size.height / self.frame.size.width;
    [projection populateFromFrustumLeft:-2 andRight:2 andBottom:-h/2 andTop:h/2 andNear:4 andFar:10];
    glUniformMatrix4fv(_projectionUniform, 1, 0, projection.glMatrix);
    
    
    
    //    ·获取那个model view uniform的传入变量
    //    ·使用cocos3d math库来创建一个新的矩阵，在变换中装入矩阵。
    //    ·变换是在z轴上移动-7，而为什么sin(当前时间) 呢？
    //    哈哈，如果你还记得高中时候的三角函数。sin()是一个从-1到1的函数。
    //    已PI（3.14）为一个周期。这样做的话，约每3.14秒，
    //    这个函数会从-1到1循环一次。
    //    ·把vertex 结构改回去，把z坐标设回0.
    //    编译运行，就算我们把z设回0，也可以看到这个位于中间的正方形了。
    
  
    // Add to render, right before call to glViewport
    CC3GLMatrix *modelView = [CC3GLMatrix matrix];
    [modelView populateFromTranslation:CC3VectorMake(sin(CACurrentMediaTime()), 0, -7)];
    
//    ·添加了一个叫_currentRotation的float，每秒会增加90度。
//    ·通过修改那个model view矩阵（这里相当于一个用于变型的矩阵），增加旋转。
//    ·旋转在x、y轴上作用，没有在z轴的。
//    编译运行，你会看到一个很有型的翻转的3D效果。
//    
    _currentRotation += displayLink.duration *5;
    [modelView rotateBy:CC3VectorMake(_currentRotation, _currentRotation, 0)];
    
    glUniformMatrix4fv(_modelViewUniform, 1, 0, modelView.glMatrix);
    
    
    // 1
    glViewport(0, 0, self.frame.size.width, self.frame.size.height);
    
    // 2
    glVertexAttribPointer(_positionSlot, 3, GL_FLOAT, GL_FALSE,
                          sizeof(Vertex), 0);
    glVertexAttribPointer(_colorSlot, 4, GL_FLOAT, GL_FALSE,
                          sizeof(Vertex), (GLvoid*) (sizeof(float) *3));
    
    // 3
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]),
                   GL_UNSIGNED_BYTE, 0);
    
    [_context presentRenderbuffer:GL_RENDERBUFFER];
    
   // [self setupDisplayLink];
}


// Add new method before init
- (void)setupDisplayLink {
    CADisplayLink* displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(render:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
}
@end
