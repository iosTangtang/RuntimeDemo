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
