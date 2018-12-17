//
//  DGVideoStrFileHandle.h
//  播放器sdk
//
//  Created by apple on 2018/12/6.
//  Copyright © 2018年 apple. All rights reserved.
//

#import <Foundation/Foundation.h>



NS_ASSUME_NONNULL_BEGIN

@interface DGVideoStrFileHandle : NSObject
#pragma mark - 字符串相关的处理
/**
 传递一个字符串转换为一个不是我们的Schemeurl
 
 @param str 传递的字符串
 @return 我们想要的scheme
 */
+ (NSURL *)customSchemeStr:(NSString *)str;
/**
 返回我们原始的url的scheme
 
 @param url 哪一个字符串
 @return 我们原始的url
 */
+ (NSURL *)originalUrl:(NSURL *)url;

#pragma mark - 文件相关
/**
 删除临时文件
 */
+ (void)deleleTempFile;
/**
 *  创建临时文件
 */
+ (void)createTempFile;
/**
 通过一个偏移量来读取临时文件的数据
 
 @param offset offset
 @param length 长度
 @return 数据
 */
+ (NSData *)readTempFileDataWithOffset:(NSUInteger )offset length:(NSUInteger)length;
/**
 往临时文件中写入数据
 
 @param data data
 */
+ (void)writeTempFileData:(NSData *)data;
/**
 存储缓存文件的数据
 
 @param str 缓存的名字
 */
+ (void)cacheTempFileData:(NSString *)str;
/**
 删除临时文件
 */
+ (void)deleteTempFile;
/**
 判断缓存文件是否存在
 
 @param linkStr 开始请求的链接
 @return 是否存在
 */
+ (BOOL)myCacheFileIsExist:(NSString *)linkStr;
/**
 获得我的缓存的文件
 
 @param linkStr 下载的链接
 @return 文件的位置
 */
+ (NSString *)getMyCacheFile:(NSString *)linkStr;
/**
 装换为md5
 
 @return 转化为md5字符串
 */
+ (NSString *)changeStrToMd5:(NSString *)changeStr;
@end

NS_ASSUME_NONNULL_END

