//
//  ViewController.h
//  Simple Download
//
//  Created by Francisco José A. C. Souza on 28/01/15.
//  Copyright (c) 2015 Francisco José A. C. Souza. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewController : UIViewController <NSURLSessionDelegate, NSURLSessionTaskDelegate, NSURLSessionDownloadDelegate, UIDocumentInteractionControllerDelegate>

@property (strong, nonatomic) IBOutlet UIProgressView *progressView;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *startDownloadButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *pauseDownloadButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *stopDownloadButton;

@property (nonatomic) NSURLSession *session;
@property (nonatomic) NSURLSessionDownloadTask *downloadTask;
@property (nonatomic) UIDocumentInteractionController *documentInteractionController;

- (IBAction)startDownload:(UIBarButtonItem *)sender;
- (IBAction)pauseDownload:(UIBarButtonItem *)sender;
- (IBAction)stopDownload:(UIBarButtonItem *)sender;

@end
