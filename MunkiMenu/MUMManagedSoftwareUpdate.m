//
//  MUMManagedSoftwareUpdate.m
//  MunkiMenu
//
//  Created by Eldon on 4/10/14.
//  Copyright (c) 2014 Eldon Ahrold. All rights reserved.
//

#import "MUMManagedSoftwareUpdate.h"

typedef NS_ENUM(NSInteger, MSUErrorCodes){
    EXIT_STATUS_OBJC_MISSING = 100,
    EXIT_STATUS_MUNKI_DIRS_FAILURE = 101,
    EXIT_STATUS_SERVER_UNAVAILABLE = 150,
    EXIT_STATUS_INVALID_PARAMETERS = 200,
    EXIT_STATUS_ROOT_REQUIRED = 201,
};

@interface MUMManagedSoftwareUpdate ()
@property (copy,nonatomic)    NSString *outputString;
@property (copy,nonatomic)    NSArray  *runErrors;
@property (copy,nonatomic)    NSError  *execError;
@property (copy)              NSArray  *arguments;
@property (nonatomic)         NSTask   *task;
@property (nonatomic)         OSStatus  exitStatus;

@end

@implementation MUMManagedSoftwareUpdate

-(instancetype)initWithArgs:(NSArray*)args{
    self = [super init];
    if(self){
        self.arguments = args;
    }
    return self;
}

-(void)run{
    self.task = [NSTask new];
    
    self.task.launchPath = @"/usr/local/munki/managedsoftwareupdate";
    
    self.task.standardOutput = [NSPipe pipe];
    self.task.standardError  = [NSPipe pipe];
    
    if(self.arguments){
        self.task.arguments = self.arguments;
    }
    
    [self.task launch];
    [self.task waitUntilExit];
}


-(NSString*)errorMsgFromCode{
    NSString * msg;
    switch (self.task.terminationStatus) {
        case EXIT_STATUS_OBJC_MISSING: msg = @"Missing python objective-c runtime";
            break;
        case EXIT_STATUS_MUNKI_DIRS_FAILURE: msg = @"There was a problem writing to the Managed Install folder, please contact your system administrator";
            break;
        case EXIT_STATUS_SERVER_UNAVAILABLE: msg = @"Could not contact the server at this time, please check your network connection and that everything is properly configured";
            break;
        case EXIT_STATUS_INVALID_PARAMETERS: msg = @"Invalid parameters were used when trying to execute managedsoftwareupdate, , please contact your system administrator";
            break;
        case EXIT_STATUS_ROOT_REQUIRED: msg = @"managedsoftwareupdate needs to be run by the root user";
            break;
        default:msg = @"unknown problem occurred";
            break;
    }
    return msg;
}

#pragma mark - Setters/Getters
-(NSArray *)runErrors{
    if(!self.task.isRunning){
        NSData *outputData = [[self.task.standardError fileHandleForReading] readDataToEndOfFile];
        NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
        
        // the above will at the least create an empty string
        // if that's all it is just ignore it.
        if(![outputString isEqualToString:@""]){
            return [outputString componentsSeparatedByString:@"\n"];
        }
    }
    return nil;
}

-(NSString *)outputString{
    if(!self.task.isRunning){
        NSData *outputData = [[self.task.standardOutput fileHandleForReading] readDataToEndOfFile];
        NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
        
        // the above will at the least create an empty string
        // if that's all it is just ignore it.
        if(![outputString isEqualToString:@""]){
            return outputString;
        }
    }
    return nil;
}

-(NSError *)execError{
    if(!self.task.isRunning){
        if(self.task.terminationStatus > 0){
            return [NSError errorWithDomain:@"com.googlecode.munki" code:self.task.terminationStatus userInfo:@{NSLocalizedDescriptionKey:[self errorMsgFromCode]}];
        }
    }
    return nil;
}

-(OSStatus)exitStatus{
    if(!self.task.isRunning){
        return  self.task.terminationStatus;
    }
    return -1;
}


#pragma mark - Class Methods / Convience
+(void)runWithArgs:(NSArray *)args reply:(void (^)(NSArray *runErrors, NSError *execError))reply{
    MUMManagedSoftwareUpdate *managedsoftwareupdate = [[MUMManagedSoftwareUpdate alloc] initWithArgs:args];
    [managedsoftwareupdate run];
    reply(managedsoftwareupdate.runErrors,managedsoftwareupdate.execError);
}

+(NSString*)version{
    MUMManagedSoftwareUpdate* managedsoftwareupdate = [[MUMManagedSoftwareUpdate alloc]initWithArgs:@[@"--version"]];
    [managedsoftwareupdate run];
    return managedsoftwareupdate.outputString;
}

+(BOOL)instanceIsRunning{
    NSTask* task = [NSTask new];
    
    NSPipe *outPipe = [NSPipe pipe];
    
    task.standardOutput = outPipe;
    task.launchPath     = @"/bin/ps";
    task.arguments      = @[@"-e",@"-o",@"command="];
    task.standardOutput = outPipe;
    task.standardError  = outPipe;
    
    [task launch];
    [task waitUntilExit];
    
    NSData *outputData = [[outPipe fileHandleForReading] readDataToEndOfFile];
    NSString *outputString = [[NSString alloc] initWithData:outputData encoding:NSUTF8StringEncoding];
    
    NSString *managedsoftwareupdate = @"/usr/local/munki/managedsoftwareupdate";
    NSString *supervisor = @"supervisor";
    NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF CONTAINS %@ and NOT SELF CONTAINS %@",managedsoftwareupdate,supervisor];
    NSArray* runningProcs = [outputString componentsSeparatedByString:@"\n"];
    
    if([[runningProcs filteredArrayUsingPredicate:predicate]count])
        return YES;
    
    return NO;
}

@end
