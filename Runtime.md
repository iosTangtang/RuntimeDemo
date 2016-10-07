#ObjC Runtime
###写在前面
本文主要是对Runtime学习的一部分总结，也是作为实验室讲课的资料，写的不好或者哪里不对的地方欢迎交流指正。
###知识结构
主要从runtime的主要几个大点进行讲解。包括 

- 何为Rumtime
- 类与对象
	1. 类的结构(基础数据结构)
	2. 实例对象、类对象、元类之间的关系
	3. 类中对应的方法的结构
- 消息转发机制
- self与super的区别
- 简单应用

###何为Runtime
什么是Runtime呢？引用Apple官方的一段话
>The Objective-C language defers as many decisions as it can from compile time and link time to runtime. Whenever possible, it does things dynamically. This means that the language requires not just a compiler, but also a runtime system to execute the compiled code. The runtime system acts as a kind of operating system for the Objective-C language; it’s what makes the language work.

这段话的意思大概就是，OC将一些静态语言在编译链接时做的事推迟到了编译链接之后，也就是运行时，这使得其更加灵活。这意味着OC不仅需要一个编译器，还需要一个运行时系统来执行编译的代码。运行时机制就像一个操作系统一样，它让所有的工作能够正常的运行。
Objc Runtime其实就是一个Runtime库，底层实现基本上是用C/C++和汇编写的。对C语言结构体及函数进行封装，再实现一些特性，使程序在运行时能够创建、修改、检查类、对象以及对应的方法。

###类与对象
介绍Runtime，从最基本的类和对象的底层实现开始。这里使用的源码是Apple官方的最新Objc源代码(objc4-680)，在底层的类的结构部分有所不同，可以从[这里](http://opensource.apple.com//tarballs/objc4/)下载最新的源码。
####类的结构
我们从OC根类--NSObject开始跟踪

NSObject.h

```
@interface NSObject <NSObject> {
    Class isa  OBJC_ISA_AVAILABILITY;
}
```
如果之前看过Runtime知识的你，对这个isa肯定不会陌生。可以看到这里的isa是个Class类型的，继续跟踪。

objc.h

```
typedef struct objc_class *Class;
```
可以看到这里的Class是个`objc_class`类型的指针，那么这里的`objc_class`是什么呢？继续跟踪。

objc-runtime-old.h

```
struct objc_class : objc_object {
    Class superclass;
    const char *name;
    uint32_t version;
    uint32_t info;
    uint32_t instance_size;
    struct old_ivar_list *ivars;
    struct old_method_list **methodLists;
    Cache cache;
    struct old_protocol_list *protocols;
    ...
}
```
objc-runtime-new.h

```
struct objc_class : objc_object {
    // Class ISA;
    Class superclass;
    cache_t cache;             // formerly cache pointer and vtable
    class_data_bits_t bits;
    ...
}
```

这里只截取部分的代码，该结构体的全部实现内容可以见源码。这里列出了两个版本的结构体定义，两个版本都是继承自objc_object结构体，旧版的定义方式很明了，从变量名就可以看出其对应的作用，本文只针对新版的进行解析，旧版的虽然结构体定义不一样，但是对整个runtime的理解影响不是很大。这里列一个表格说明旧版的部分变量的作用。

| 变量名       | 作用         |
| :-------------: |:-------------:|
| superclass   | 指向父类的指针 |
| name      | 变量名 | 
| version | 类的版本信息，默认为0 |
|  info | 类信息，供运行期使用的一些位标识 |
|  instance_size | 类该类的实例变量大小 |
|  ivars | 该类的成员变量列表 |
|  methodLists | 该类的方法定义的链表 |
|  cache | 方法的缓存 |
| protocols | 所包含的协议链表 |

新版的定义较旧版的相比，看起来简洁了许多，可是这背后真的有那么简单吗？这个我们下一节来讨论。cache的作用同样是方法缓存，只不过新版的结构体类型不相同。这里的`class_data_bits_t`是之前没见过的一个结构体，你们可以猜猜这个是干嘛的，具体会在后面解释。

我们再来看看这个神秘的objc_object

objc_object.h

```
struct objc_object {
private:
    isa_t isa;

public:

    // ISA() assumes this is NOT a tagged pointer object
    Class ISA();

    // getIsa() allows this to be a tagged pointer object
    Class getIsa();
    ...
}
```
同样只截取了部分代码，具体可以参见源码。如果之前了解过isa的同学会发现，isa的类型变了，由原来的Class变为了`isa_t`。这种变化主要是为了优化其在`__arm64__`和`__x86_64__`二者的cpu上的内存使用，说通俗点就是在iOS和macOS上的内存优化。这里不对这个结构体进行过多阐述，你可以点击[这里](http://www.jianshu.com/p/e694678be145)来了解其作用。

####实例对象、类对象、元类之间的关系
从上一节我们知道了类的数据结构，那么其中的isa指针是干嘛的呢？接触过Runtime的人应该多多少少了解一些。这里的isa牵扯到OC中类的实现及存储方式。我们都知道，OC中类的方法分为类方法和实例方法，这些方法分别是存在哪儿的？这里提几个名词，类对象和元类。

在OC中我们可以给对象发送消息，即调用实例方法，我们还可以像下面这样调用类方法。

```
NSArray *array = [NSArray array];
```
说明，在OC中，类其实也是一个对象，即**类对象**，所有的类的实例就是由类对象进行初始化得来的。既然类也是个对象，那它是由谁而来的？答案是**元类**。而连接这一切的，正是这个**isa**指针。
![类、类对象、元类之间的关系](http://upload-images.jianshu.io/upload_images/1975281-cc44a16eb3f252d3.jpg?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

正如上图所示，实例对象、类对象、元类对象中都存在一个isa指针，实例对象的isa指针指向类对象，实例对象中存储着实例变量和属性，而实例方法存在于类对象中，这样设计的目的也是为了节省内存空间(想想如果每个实例对象都保存着自己能执行的方法，那么对内存将是很大的负担)。类对象所能响应的方法--类方法，存放在元类中，同样类对象的isa指针指向了元类，即如果你向类对象发送消息的话，会在元类中寻找对应的方法。元类的isa指针则指向了根类的元类，根类的元类的isa指针则指向了自己。

这里说明一下，类对象和元类在内存中各自仅存在一份，也就是说，二者皆为单例。原因很简单，对某个类的描述仅存在一份即可，需要时可通过此描述来克隆(说克隆也不是很对，大概意思)出其他的对象。实例对象既然是从类对象而来，那么我们可以从类对象这里得到很多实例对象，而类对象只需一个即可。同样元类也是一样，但是这里生成的类对象只需一份即可。

我们可以在代码中去验证这个关系链，举个例子。点击[这里](https://github.com/iosTangtang/RuntimeDemo.git)下载Demo。

ClassAndObject.h

```
    NSLog(@"point                           %p", &self);
    NSLog(@"instance                        %p", self);
    NSLog(@"class                           %p", object_getClass(self));
    NSLog(@"meta class                      %p", object_getClass([self class]));
    NSLog(@"root class                      %p", object_getClass(object_getClass([self class])));
    NSLog(@"root meta's meta class          %p", object_getClass(object_getClass(object_getClass([self class]))));
```

```
    NSLog(@"instance                        %@", self);
    NSLog(@"class                           %@", object_getClass(self));
    NSLog(@"meta class                      %@", object_getClass([self class]));
    NSLog(@"root class                      %@", object_getClass(object_getClass([self class])));
    NSLog(@"root meta's meta class          %@", object_getClass(object_getClass(object_getClass([self class]))));
```

打印结果

```
2016-10-06 16:43:49.057 RuntimeDemo[2768:87818] >>>>>>ClassAndObject showAddressMethod<<<<<<
2016-10-06 16:43:49.057 RuntimeDemo[2768:87818] point                           0x7fff527949a8
2016-10-06 16:43:49.058 RuntimeDemo[2768:87818] instance                        0x618000005360
2016-10-06 16:43:49.058 RuntimeDemo[2768:87818] class                           0x10d46c328
2016-10-06 16:43:49.058 RuntimeDemo[2768:87818] meta class                      0x10d46c300
2016-10-06 16:43:49.058 RuntimeDemo[2768:87818] root class                      0x10de09e08
2016-10-06 16:43:49.058 RuntimeDemo[2768:87818] root meta's meta class          0x10de09e08
2016-10-06 16:43:49.059 RuntimeDemo[2768:87818] >>>>>>ClassAndObject showRelationMethod<<<<<<
2016-10-06 16:43:49.059 RuntimeDemo[2768:87818] instance                        <ClassAndObject: 0x618000005360>
2016-10-06 16:43:49.059 RuntimeDemo[2768:87818] class                           ClassAndObject
2016-10-06 16:43:49.059 RuntimeDemo[2768:87818] meta class                      ClassAndObject
2016-10-06 16:43:49.718 RuntimeDemo[2768:87818] root class                      NSObject
2016-10-06 16:43:49.718 RuntimeDemo[2768:87818] root meta's meta class          NSObject
```

从打印结果来看，确实验证了我们的猜想，最后都走向了NSObject的元类。这里有一点需要注意，跟踪的时候，不能直接调用class方法，否则无法得到正确结果。这与class的实现有关，具体看[这里](http://www.jianshu.com/p/54c190542aa8)。

对元类的更多解释，点击[这里](http://www.cocoawithlove.com/2010/01/what-is-meta-class-in-objective-c.html)了解(注: 该博客为英文，慎重食用)。

####类中对应的方法的结构
这节来说说上面遗留的新版objc_class中的`class_data_bits_t`结构体，它究竟是用来干什么的？对比新旧两版的runtime可以发现，新版中对于成员变量列表、方法列表、协议列表的定义消失了，它们去哪儿了？我们顺着`class_data_bits_t`来跟踪下去。

objc-runtime-new.h

```
struct class_data_bits_t {

    // Values are the FAST_ flags above.
    uintptr_t bits;
    ...
}
```
这个结构体的变量就只有一个`bits`，似乎我们发现不了什么端倪，但是仔细看看objc_class结构体中对class_data_bits_t的注释

```
class_data_bits_t bits;    // class_rw_t * plus custom rr/alloc flags
```

这里注释写到，`class_data_bits_t`相当于`class_rw_t`加上`rr/alloc`，即提供了便携方法返回`class_rw_t *`指针。在`class_data_bits_t`结构体中寻找发现。

objc-runtime-new.h

```
    class_rw_t* data() {
        return (class_rw_t *)(bits & FAST_DATA_MASK);
    }
    void setData(class_rw_t *newData)
    {
        assert(!data()  ||  (newData->flags & (RW_REALIZING | RW_FUTURE)));
        // Set during realization or construction only. No locking needed.
        bits = (bits & ~FAST_DATA_MASK) | (uintptr_t)newData;
    }
```

即`class_data_bits_t`本质上还是`class_rw_t `指针。说明端倪还在`class_rw_t `中。继续跟踪。

objc-runtime-new.h

```
struct class_rw_t {
    uint32_t flags;
    uint32_t version;

    const class_ro_t *ro;

    method_array_t methods;
    property_array_t properties;
    protocol_array_t protocols;

    Class firstSubclass;
    Class nextSiblingClass;
}
```

果然，发现了属性列表、方法列表和协议列表。进入`class_ro_t`。

objc-runtime-new.h

```
struct class_ro_t {
    uint32_t flags;
    uint32_t instanceStart;
    uint32_t instanceSize;
#ifdef __LP64__
    uint32_t reserved;
#endif

    const uint8_t * ivarLayout;
    
    const char * name;
    method_list_t * baseMethodList;
    protocol_list_t * baseProtocols;
    const ivar_list_t * ivars;

    const uint8_t * weakIvarLayout;
    property_list_t *baseProperties;

    method_list_t *baseMethods() const {
        return baseMethodList;
    }
};
```

这样就非常清楚了。`class_ro_t`是保存类在编译时期就已经确定的属性、方法和协议，即编译时，`class_data_bits_t`的指向为`class_ro_t`变量，当程序运行起来时，调用方法强制将`class_rw_t`转换为`class_ro_t `，然后初始化一个`class_rw_t`结构体变量，设置ro值和flags值，最后设置正确的data即可。上述过程可以表示为如下。

编译时
![编译时](http://upload-images.jianshu.io/upload_images/1975281-96a53fc868406a0c.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

运行时
![](http://upload-images.jianshu.io/upload_images/1975281-0bbf368d247b4142.png?imageMogr2/auto-orient/strip%7CimageView2/2/w/1240)

(图片引用自Draveness)

代码验证过程你可以点击[这里](http://www.jianshu.com/p/d7a60fc7b0a1)来查看思路。该博客的博主对此过程的跟踪挺详细的，这里就不做示例了。

###消息转发机制
在介绍消息转发机制之前，先介绍下SEL、IMP、Method。

####SEL
SEL又叫选择子，表示一个方法的selector的指针。定义为

objc.h

```
typedef struct objc_selector *SEL;
```
很遗憾没找到objc_selector结构体。OC在编译的时候，会根据每一个方法的名字、参数序列，生成唯一的一个整型标识(地址)，即SEL。

```
 SEL sel = @selector(hello);
 NSLog(@"sel             %p", sel);
```
如上代码，会有如下结果

```
sel             0x1049f77b0
```
即生成了一个整型标识。这个SEL值，不管你的方法是在父类还是子类，还是完全不相关的两个类，只要方法名一样，SEL值就是一样的，即使参数类型不一样，但同样还是相同的。但是，参数个数不一样SEL的值就不一样。验证如下

ClassAndObject.h

```
- (void)hello:(NSInteger)index {
    NSLog(@">>>>>>ClassAndObject hello<<<<<<");
}

- (void)showHelloMethodSEL {
    NSLog(@">>>>>>ClassAndObject showHelloMethodSEL<<<<<<");
    SEL sel = @selector(hello:);
    NSLog(@"sel             %p", sel);
}
```

MethodObject.h

```
- (void)hello:(NSString *)string {
    NSLog(@">>>>>>MethodObject hello<<<<<<");
}

- (void)showHelloMethodSEL {
    NSLog(@">>>>>>MethodObject showHelloMethodSEL<<<<<<");
    SEL sel = @selector(hello:);
    NSLog(@"sel             %p", sel);
    
}
```

打印结果如下

```
2016-10-07 15:18:49.891 RuntimeDemo[6696:317089] >>>>>>MethodObject showHelloMethodSEL<<<<<<
2016-10-07 15:18:49.891 RuntimeDemo[6696:317089] sel             0x10b3add82
2016-10-07 15:18:49.891 RuntimeDemo[6696:317089] >>>>>>ClassAndObject showHelloMethodSEL<<<<<<
2016-10-07 15:18:49.891 RuntimeDemo[6696:317089] sel             0x10b3add82
```

可以发现，SEL的值是一样的。

工程中的所有的SEL组成一个Set集合，Set的特点就是唯一，因此SEL是唯一的。相当于OC给我们维护了一张巨大的表，在编译的时候将所有的方法以及使用`@selector()`生成的选择子都存入这个集合中，在查找的时候，如果发现表中没有，将当前的选择子也存入集合中。SEL实际上是根据方法名hash化的字符串，对于字符串只要比较其地址即可，所以在查找的时候，速度是非常快的。但是这里可能存在一个缺陷，当你的方法数量变大，会增加hash冲突而导致性能下降，只要能够将数量变少，这个方法还是不错的。

####IMP
IMP就相当于一个函数指针，指向对应的方法实现。

objc.h

```
#if !OBJC_OLD_DISPATCH_PROTOTYPES
typedef void (*IMP)(void /* id, SEL, ... */ ); 
#else
typedef id (*IMP)(id, SEL, ...); 
#endif
```

第一个参数是指向self的指针(如果是实例方法，则是类实例的内存地址；如果是类方法，则是指向元类的指针)，第二个参数是方法选择器(selector)，接下来是方法的实际参数列表。每个SEL都对应一个IMP，通过查找SEL就可以找到IMP，即可获得函数的实现。

####Method
Method的结构如下

```
typedef struct objc_method *Method;

struct objc_method {
    SEL method_name                                          OBJC2_UNAVAILABLE;
    char *method_types                                       OBJC2_UNAVAILABLE;
    IMP method_imp                                           OBJC2_UNAVAILABLE;
}                                                            OBJC2_UNAVAILABLE;
```

从Method的结构就可以看出来，这个结构体就是连接SEL和IMP的，即有了这个结构体，我们就可以实现一个SEL对应一个IMP。

####方法调用流程
在OC中，我们像如下这样调用方法

```
[self runtime_method];
```

这个表达式会转换为一个方法调用，即`objc_msgSend `。该函数的定义如下

```
OBJC_EXPORT id objc_msgSend(id self, SEL op, ...)
```
这个函数完成了动态绑定的所有事情：

1. 首先它找到selector对应的方法实现。因为同一个方法可能在不同的类中有不同的实现，所以我们需要依赖于接收者的类来找到的确切的实现。

2. 它调用方法实现，并将接收者对象及方法的所有参数传给它。

3. 最后，它将实现返回的值作为它自己的返回值。

下图展示了发送一个消息查找的基本流程
![消息查找](https://developer.apple.com/library/content/documentation/Cocoa/Conceptual/ObjCRuntimeGuide/Art/messaging1.gif)

当消息发送给一个对象时，`objc_msgSend`通过对象的isa指针获取到类的结构体，然后在方法分发表里面查找方法的selector。如果 没有找到selector，则通过`objc_msgSend`结构体中的指向父类的指针找到其父类，并在父类的分发表里面查找方法的selector。依 此，会一直沿着类的继承体系到达NSObject类。一旦定位到selector，函数会就获取到了实现的入口点，并传入相应的参数来执行方法的具体实 现。如果最后没有定位到selector，则会走消息转发流程。为了加速消息的处理，运行时系统缓存使用过的selector及对应的方法的地址。

####消息转发
如果当前调用的方法不存在的话，就会触发消息转发机制，通过这一机制，我们可以告诉对象如何处理未知消息。消息转发机制主要分为以下三个步骤。

1. 动态方法解析
2. 备用接收者
3. 完整的消息转发

####动态方法解析
对象在接收到未知消息的时候，首先会调用所属类的类方法`+resolveInstanceMethod:`或`+resolveClassMethod:`，在这个方法中，我们可以为该未知消息新增一个处理方法。前提是我们需要实现该方法。

MethodObject.h

```
void functionMethod(void) {
    NSLog(@"%s", __FUNCTION__);
}

//实例方法
+ (BOOL)resolveInstanceMethod:(SEL)sel {
    NSLog(@"%s", __FUNCTION__);
    
    NSString *selSelector = NSStringFromSelector(sel);
    
    if ([selSelector isEqualToString:@"method"]) {
        class_addMethod([self class], @selector(method), (IMP)functionMethod, "@:");
    }
    
    return [super resolveInstanceMethod:sel];
}
```

```
2016-10-07 16:16:38.983 RuntimeDemo[7390:366991] +[MethodObject resolveInstanceMethod:]
2016-10-07 16:16:38.983 RuntimeDemo[7390:366991] functionMethod

```

####备用接收者
如果上一步无法处理，那么Runtime就会继续调用下面的方法

```
- (id)forwardingTargetForSelector:(SEL)aSelector
```

使用这个方法通常是在对象内部，可能还有一系列其它对象能处理该消息，我们便可借这些对象来处理消息并返回，这样在对象外部看来，还是由该对象亲自处理了这一消息。

```
@interface MethodHelper : NSObject

- (void)method;

@end

@implementation MethodHelper

- (void)method {
    NSLog(@"%s", __FUNCTION__);
}

@end
```

```
@interface MethodObject () {
    MethodHelper *_helper;
}

@end

- (id)forwardingTargetForSelector:(SEL)aSelector {
    NSLog(@"%s", __FUNCTION__);
    
    NSString *selSelector = NSStringFromSelector(aSelector);
    
    if ([selSelector isEqualToString:@"method"]) {
        return _helper;
    }
    
    return [super forwardingTargetForSelector:aSelector];
}
```

(这里注意方法名需要一样)

这一步合适于我们只想将消息转发到另一个能处理该消息的对象上。但这一步无法对消息进行处理，如操作消息的参数和返回值。

####完整的消息转发
若上一步还是无法处理，则会启用完整的消息转发机制。调用以下方法

```
- (void)forwardInvocation:(NSInvocation *)anInvocation
```
运行时系统会在这一步给消息接收者最后一次机会将消息转发给其它对象。对象会创建一个表示消息的NSInvocation对象，把与尚未处理的消息 有关的全部细节都封装在anInvocation中，包括selector，目标(target)和参数。我们可以在forwardInvocation 方法中选择将消息转发给其它对象。

forwardInvocation:方法的实现有两个任务：

1. 定位可以响应封装在anInvocation中的消息的对象。这个对象不需要能处理所有未知消息。
2. 使用anInvocation作为参数，将消息发送到选中的对象。anInvocation将会保留调用结果，运行时系统会提取这一结果并将其发送到消息的原始发送者。

在这个方法中我们可以实现一些更复杂的功能，我们可以对消息的内容进行修改，比如追回一个参数等，然后再去触发消息。另外，若发现某个消息不应由本类处理，则应调用父类的同名方法，以便继承体系中的每个类都有机会处理此调用请求。

在这一步中，我们必须重写下面这个方法

```
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector
```

消息转发机制使用从这个方法中获取的信息来创建NSInvocation对象。因此我们必须重写这个方法，为给定的selector提供一个合适的方法签名。

例子

MethodObject.h

```
- (NSMethodSignature *)methodSignatureForSelector:(SEL)aSelector {
    NSLog(@"%s", __FUNCTION__);
    
    NSMethodSignature *signature = [super methodSignatureForSelector:aSelector];
    
    if (!signature) {
        if ([MethodHelper instancesRespondToSelector:aSelector]) {
            signature = [MethodHelper instanceMethodSignatureForSelector:aSelector];
        }
    }
    
    return signature;
}

- (void)forwardInvocation:(NSInvocation *)anInvocation{
    NSLog(@"%s", __FUNCTION__);
    
    if ([MethodHelper instancesRespondToSelector:anInvocation.selector]) {
        [anInvocation invokeWithTarget:_helper];
    }
}

```

```
2016-10-07 18:45:58.859 RuntimeDemo[8154:423365] +[MethodObject resolveInstanceMethod:]
2016-10-07 18:45:58.860 RuntimeDemo[8154:423365] -[MethodObject forwardingTargetForSelector:]
2016-10-07 18:45:58.860 RuntimeDemo[8154:423365] -[MethodObject methodSignatureForSelector:]
2016-10-07 18:45:58.860 RuntimeDemo[8154:423365] +[MethodObject resolveInstanceMethod:]
2016-10-07 18:45:58.861 RuntimeDemo[8154:423365] -[MethodObject forwardInvocation:]
2016-10-07 18:45:58.861 RuntimeDemo[8154:423365] -[MethodHelper method]
```

从上也可以看出整个消息转发过程。

NSObject的forwardInvocation:方法实现只是简单调用了doesNotRecognizeSelector:方法，它不会转发任何消息。这样，如果不在以上所述的三个步骤中处理未知消息，则会引发一个异常。

forwardInvocation:就像一个未知消息的分发中心，将这些未知的消息转发给其它对象。或者也可以像一个运输站一样将所有未知消息都发送给同一个接收对象。

####深入Objc_msgSend
本小节主要讲下OC中消息的发送过程，也可以说是方法的查找过程。主要步骤如下

1. 缓存是否命中
2. 查找当前类的缓存及方法
3. 查找父类的缓存及方法
4. 方法决议(即消息转发机制的第一步，动态方法解析)
5. 消息转发

####无缓存
无缓存，即方法为第一次调用，暂时没有缓存到缓存池中。可以跟踪一下objc_msgSend方法的调用栈，调用栈如下：

```
0 lookUpImpOrForward
1 _class_lookupMethodAndLoadCache3
2 objc_msgSend
3 main
4 start
```
可以发现，`objc_msgSend`之后，还随之调用了两个方法，首先调用的是`_class_lookupMethodAndLoadCache3`，跟踪进去看看其实现如下

objc-runtime-new.mm

```
IMP _class_lookupMethodAndLoadCache3(id obj, SEL sel, Class cls)
{
    return lookUpImpOrForward(cls, sel, obj, 
                              YES/*initialize*/, NO/*cache*/, YES/*resolver*/);
}
```
可以看到，这个方法只是对第二个方法`lookUpImpOrForward `的调用，而这个方法，正是查找的主方法，这个方法内部调用的方法很多，有兴趣可以去objc-class-old.mm里面去查看源码。说说它的主要步骤

1. 无锁的缓存查找
2. 如果类没有实现（isRealized）或者初始化（isInitialized），实现或者初始化类
3. 加锁
4. 缓存以及当前类中方法的查找
5. 尝试查找父类的缓存以及方法列表
6. 没有找到实现，尝试方法解析器
7. 进行消息转发
8. 解锁、返回实现

####无锁的缓存查找
在没有加锁的情况下，对缓存进行查找，提高查找效率。当然如果是第一次调用方法的话，这个步骤会跳过。

源代码

```
methodListLock.assertUnlocked();

 // Optimistic cache lookup
 if (cache) {
        methodPC = _cache_getImp(cls, sel);
        if (methodPC) return methodPC;    
 }
```

####类的实现和初始化
在运行中会对类进行第一次初始化，初始化调用`realizeClass `方法。

源代码

```
if (cls == _class_getFreedObjectClass())
        return (IMP) _freedHandler;

 // Check for +initialize
 if (initialize  &&  !cls->isInitialized()) {
        _class_initialize (_class_getNonMetaClass(cls, inst));
        // If sel == initialize, _class_initialize will send +initialize and 
        // then the messenger will send +initialize again after this 
        // procedure finishes. Of course, if this is not being called 
        // from the messenger then it won't happen. 2778172
 }
```

####加锁
加锁的代码只有一行，其主要目的保证方法查找以及缓存填充（cache-fill）的原子性，保证在运行以下代码时不会有新方法添加导致缓存被清楚（flush）。

源代码

```
methodListLock.lock();
```

####查找当前类

源代码中的实现，调用了`_cache_getImp()`方法。

源代码

```
methodPC = _cache_getImp(cls, sel);
if (methodPC) goto done;
```
`_cache_getImp()`方法并不是开源的，Apple在这块儿使用了汇编来实现这个方法，原因很简单，就是保证了查找的高效性。

如果在缓存中找到了方法，就会调到done标签。如果没有，就会执行下面代码

源代码

```
meth = _class_getMethodNoSuper_nolock(cls, sel);
if (meth) {
        log_and_fill_cache(cls, cls, meth, sel);
        methodPC = method_getImplementation(meth);
        goto done;
}
```

就是在当前类中对查找所对应的方法。

源代码

```
static Method _class_getMethodNoSuper_nolock(Class cls, SEL sel)
{
    methodListLock.assertLocked();
    return (Method)_findMethodInClass(cls, sel);
}

static inline old_method * _findMethodInClass(Class cls, SEL sel) {
    // Flattened version of nextMethodList(). The optimizer doesn't 
    // do a good job with hoisting the conditionals out of the loop.
    // Conceptually, this looks like:
    // while ((mlist = nextMethodList(cls, &iterator))) {
    //     old_method *m = _findMethodInList(mlist, sel);
    //     if (m) return m;
    // }

    if (!cls->methodLists) {
        // No method lists.
        return nil;
    }
    else if (cls->info & CLS_NO_METHOD_ARRAY) {
        // One method list.
        old_method_list **mlistp;
        mlistp = (old_method_list **)&cls->methodLists;
        *mlistp = fixupSelectorsInMethodList(cls, *mlistp);
        return _findMethodInList(*mlistp, sel);
    }
    else {
        // Multiple method lists.
        old_method_list **mlistp;
        for (mlistp = cls->methodLists; 
             *mlistp != nil  &&  *mlistp != END_OF_METHODS_LIST; 
             mlistp++) 
        {
            old_method *m;
            *mlistp = fixupSelectorsInMethodList(cls, *mlistp);
            m = _findMethodInList(*mlistp, sel);
            if (m) return m;
        }
        return nil;
    }
}

```

实现中有许多小细节，包括如何查找、查找到需要加入缓存、缓存内容大于容量的3/4的时候会清空缓存、清空缓存时会将缓存清空等。有兴趣的可以去源码中查看理解。

####在父类中查找

源代码

```
curClass = cls;
    while ((curClass = curClass->superclass)) {
        // Superclass cache.
        meth = _cache_getMethod(curClass, sel, _objc_msgForward_impcache);
        if (meth) {
            if (meth != (Method)1) {
                // Found the method in a superclass. Cache it in this class.
                log_and_fill_cache(cls, curClass, meth, sel);
                methodPC = method_getImplementation(meth);
                goto done;
            }
            else {
                // Found a forward:: entry in a superclass.
                // Stop searching, but don't cache yet; call method 
                // resolver for this class first.
                break;
            }
        }

        // Superclass method list.
        meth = _class_getMethodNoSuper_nolock(curClass, sel);
        if (meth) {
            log_and_fill_cache(cls, curClass, meth, sel);
            methodPC = method_getImplementation(meth);
            goto done;
        }
    }
```

实现过程也是差不多的，先查找缓存，之后查找方法列表。

####没有找到实现，尝试方法解析器

源代码

```
if (resolver  &&  !triedResolver) {
        methodListLock.unlock();
        _class_resolveMethod(cls, sel, inst);
        triedResolver = YES;
        goto retry;
}
```
可以看出，这里就在进行方法决议，即进行消息转发第一阶段--动态方法解析。当然是建立在都没有查找到方法的情况下。

源代码

```
void _class_resolveMethod(Class cls, SEL sel, id inst)
{
    if (! cls->isMetaClass()) {
        // try [cls resolveInstanceMethod:sel]
        _class_resolveInstanceMethod(cls, sel, inst);
    } 
    else {
        // try [nonMetaClass resolveClassMethod:sel]
        // and [cls resolveInstanceMethod:sel]
        _class_resolveClassMethod(cls, sel, inst);
        if (!lookUpImpOrNil(cls, sel, inst, 
                            NO/*initialize*/, YES/*cache*/, NO/*resolver*/)) 
        {
            _class_resolveInstanceMethod(cls, sel, inst);
        }
    }
}
```

从这段代码更容易看出，其实就是在调用`+resolveInstanceMethod:`或`+resolveClassMethod:`两个方法来出来消息。

####消息转发
最后，若未处理成功，进入消息转发的第二第三阶段。

源代码

```
_cache_addForwardEntry(cls, sel);
methodPC = _objc_msgForward_impcache;
```

这样就进行了第一次调用方法的整个过程。思路还是挺好理解的，也很符合逻辑。当第二次调用该方法时，跟踪发现，整个过程变化很大，不会调用`lookUpImpOrForward `，也就是说，方法缓存调用直接在`objc_msgSend`方法中就实现了。

其实`objc_msgSend`方法也是使用汇编编写的，在其中加入了缓存查找的实现，当然这一切都是为了查找的高效性。

讲到这，整个方法的调用过程也差不多讲完了，其实思路还是很好理解的，就是实现中的一些小细节的问题。

###self与super的区别
self和super两个是不同的，self是类的一个隐藏参数，每个方法的实现的第一个参数即为self。而super不是一个隐藏参数，它实际上只是一个”编译器标示符”，它负责告诉编译器，当调用viewDidLoad方法时，去调用父类的方法，而不是本类中的方法。我们可以看看super的定义。

message.h

```
#ifndef OBJC_SUPER
#define OBJC_SUPER

/// Specifies the superclass of an instance. 
struct objc_super {
    /// Specifies an instance of a class.
    __unsafe_unretained id receiver;

    /// Specifies the particular superclass of the instance to message. 
#if !defined(__cplusplus)  &&  !__OBJC2__
    /* For compatibility with old objc-runtime.h header */
    __unsafe_unretained Class class;
#else
    __unsafe_unretained Class super_class;
#endif
    /* super_class is the first class to search */
};
#endif
```

这个结构体，抛去这些宏判断不看，实际上可以看成是包含了两个变量，`receiver `是消息的实际接收者，`super_class`是指向当前类的父类。当我们使用super来接收消息时，编译器会生成一个objc_super结构体。发送消息时，就不是使用`objc_msgSend`方法了，而是`objc_msgSendSuper`，其声明如下

message.h

```
id objc_msgSendSuper(struct objc_super *super, SEL op, ...)
```

其实跟`objc_msgSend`类似，只是第一个参数不再是self了，而是生成的super结构体。该函数实际的操作是：从objc_super结构体指向的superClass的方法列表开始查找调用方法的selector，找到后以objc->receiver去调用这个selector，而此时的操作流程就是如下方式了。

```
objc_msgSend(objc_super->receiver, @selector(xxxxx))
```
其实，`objc_super->receiver`就相当于`self`，上面的操作其实也就是

```
objc_msgSend(self, @selector(xxxxx))
```

其实就相当于父类调用了那个方法，发送了消息。

###简单应用
关于Runtime的应用有挺多的，[这里](http://gold.xitu.io/entry/57f26be0a0bb9f00580a4ba7)总结的挺多的。本节就提几个常用的。

- Method Swizzling
- Associated Object关联对象
- 动态的增加方法
- 字典和模型互相转换

####Method Swizzling
这个算Runtime的一个黑魔法，可以在运行中动态交换方法的实现。

```
+ (void)load {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        Class class = [self class];
        
        SEL originalSelector = @selector(methodExchange1);
        SEL swizzledSelector = @selector(methodExchange2);
        
        Method originalMethod = class_getInstanceMethod(class, originalSelector);
        Method swizzledMethod = class_getInstanceMethod(class, swizzledSelector);
        
        BOOL didAddMethod =
        class_addMethod(class,
                        originalSelector,
                        method_getImplementation(swizzledMethod),
                        method_getTypeEncoding(swizzledMethod));
        
        if (didAddMethod) {
            class_replaceMethod(class,
                                swizzledSelector,
                                method_getImplementation(originalMethod),
                                method_getTypeEncoding(originalMethod));
        } else {
            method_exchangeImplementations(originalMethod, swizzledMethod);
        }
    });
}


- (void)methodExchange1 {
    NSLog(@"change method %s", __FUNCTION__);
}

- (void)methodExchange2 {
    NSLog(@">>>>>>RuntimeObject MethodExchange<<<<<<");
    
    NSLog(@"%s", __FUNCTION__);
    
    [self methodExchange2];
}
```

```
2016-10-07 21:45:25.534 RuntimeDemo[9715:524715] >>>>>>RuntimeObject methodExchange<<<<<<
2016-10-07 21:45:25.534 RuntimeDemo[9715:524715] -[RuntimeObject methodExchange2]
2016-10-07 21:45:25.534 RuntimeDemo[9715:524715] change method -[RuntimeObject methodExchange1]
```

这里要注意两个问题

- Swizzling应该总是在+load中执行
- Swizzling应该总是在dispatch_once中执行

####Swizzling应该总是在+load中执行
在Objective-C中，运行时会自动调用每个类的两个方法。+load会在类初始加载时调用，+initialize会在第一次调用类的类方法或实例方法之前被调用。这两个方法是可选的，且只有在实现了它们时才会被调用。由于method swizzling会影响到类的全局状态，因此要尽量避免在并发处理中出现竞争的情况。+load能保证在类的初始化过程中被加载，并保证这种改变应用级别的行为的一致性。相比之下，+initialize在其执行时不提供这种保证—事实上，如果在应用中没为给这个类发送消息，则它可能永远不会被调用。

####Swizzling应该总是在dispatch_once中执行
与上面相同，因为swizzling会改变全局状态，所以我们需要在运行时采取一些预防措施。原子性就是这样一种措施，它确保代码只被执行一次，不管有多少个线程。GCD的dispatch_once可以确保这种行为，我们应该将其作为method swizzling的最佳实践。


####Associated Object关联对象

```
// 设置关联对象
void objc_setAssociatedObject ( id object, const void *key, id value, objc_AssociationPolicy policy );

// 获取关联对象
id objc_getAssociatedObject ( id object, const void *key );

// 移除关联对象
void objc_removeAssociatedObjects ( id object );
```

主要就是使用以上几个方法来关联对象。

举例说明使用方法

```
#import "RuntimeObject.h"

@interface RuntimeObject (associated)

@property (nonatomic, strong) id associatedObject;

@end


#import "RuntimeObject+associated.h"
#import <objc/runtime.h>

@implementation RuntimeObject (associated)
@dynamic associatedObject;

- (void)setAssociatedObject:(id)associatedObject {
    NSLog(@">>>>>>RuntimeObject+associated associatedObject<<<<<<");
    
    objc_setAssociatedObject(self, @selector(associatedObject), associatedObject, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

- (id)associatedObject {
    return objc_getAssociatedObject(self, @selector(associatedObject));
}

[run setAssociatedObject:@"runtime_runtimeObject_associated"];
    
NSLog(@"%@", run.associatedObject);

```
主要是用在给系统类采用类别来自定义添加部分属性。

####动态的增加方法
这块在之前的消息转发第一阶段的`+ (BOOL)resolveInstanceMethod:(SEL)sel`里面提到过，这里就不再详说。

```
+ (BOOL)resolveInstanceMethod:(SEL)sel {
    NSLog(@"%s", __FUNCTION__);
    
    NSString *selSelector = NSStringFromSelector(sel);
    
    if ([selSelector isEqualToString:@"method"]) {
        class_addMethod([self class], @selector(method), (IMP)functionMethod, "@:");
    }
    
    return [super resolveInstanceMethod:sel];
}
```

####字典和模型互相转换
这块应用就很广了，有许多字典转模型的框架，主要思想就是获取模型中的属性然后一一对应上去。这里就不做详说，可以参考大部分的字典转模型框架。

###最后
Runtime其实细节也是挺多的，这里只是对偏底层的东西说明一下，具体的有兴趣可以去看源码。
