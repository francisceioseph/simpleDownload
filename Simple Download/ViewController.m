//
//  ViewController.m
//  Simple Download
//
//  Created by Francisco José A. C. Souza on 28/01/15.
//  Copyright (c) 2015 Francisco José A. C. Souza. All rights reserved.
//

#import "ViewController.h"
#import "AppDelegate.h"

@interface ViewController ()
{

    NSString *downloadURLString;
    NSData *taskResumeData;
}
@end

@implementation ViewController

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [self setUpDownloadTask];
    
	downloadURLString = @"https://copy.com/IQOfvVTn1ZTuTFzR/apostila_bd_out2013.pdf?download=1";
    self.session = [self backgroundSession];
    
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
}

#pragma mark Inicialização

/*
 * Faz a inicialização de algumas variáveis e
 * configura alguns dispositivos de UI para a
 * rodar o aplicativo.
 *
 * Este método também pode ser utilizado para
 * alguma reinicialização que for necessária.
 */
- (void) setUpDownloadTask
{
    self.downloadTask = nil;
    taskResumeData = nil;
    [self.progressView setProgress:0];
    [self.progressView setHidden:YES];
}

#pragma mark Manipulação de UI
/*
 * Configura os botões da toolbar da View
 * principal.
 * startDownloadButton: Disabled
 * stopDownloadButton: Enabled
 * pauseDownloadButton: Enabled
 */
- (void) configureButtonsOnStartDownload
{
    [self.startDownloadButton setEnabled:NO];
    [self.stopDownloadButton setEnabled:YES];
    [self.pauseDownloadButton setEnabled:YES];
}

/*
 * Configura os botões da toolbar da View
 * principal.
 * startDownloadButton: Enabled
 * stopDownloadButton: Disabled
 * pauseDownloadButton: Disabled
 */
- (void) configureButtonsOnPauseOrStopDownload
{
    [self.startDownloadButton setEnabled:YES];
    [self.stopDownloadButton setEnabled:NO];
    [self.pauseDownloadButton setEnabled:NO];
}

/*
 * Este método é responsável por tratar o evento
 * de click no botão startDownloadButton e irá
 * ser responsável por iniciar ou reinicializar
 * a task que fazer o download do arquivo PDF.
 */
- (IBAction)startDownload:(UIBarButtonItem *)sender
{
    /*
     * Testa se o usuário já havia iniciado um
     * download. 
     * Se ele não tiver inciado nenhum download
     * ele cria uma nova task e inicia o download.
     * Se não ele cria uma task com os dados já 
     * baixados e a reinicia.
     */
    if (!self.downloadTask)
    {
        NSURL *downloadURL = [NSURL URLWithString:downloadURLString];
        NSURLRequest *request = [NSURLRequest requestWithURL:downloadURL];
        
        self.downloadTask = [self.session downloadTaskWithRequest:request];
        [self.progressView setHidden:NO];
        [self.downloadTask resume];
    }
    else
    {
        self.downloadTask = [self.session downloadTaskWithResumeData:taskResumeData];
        [self.downloadTask resume];
    }
    
    /*
     * Configura os botões da toolbar
     */
    [self configureButtonsOnStartDownload];
    
}

/*
 * Este método é responsável por tratar o evento
 * toque no botão pause da toolbar. Ele finalizará
 * a task que está fazendo download do aquivo PDF, 
 * mas salvará os dados já baixados para que a operação
 * possa ser retomada posteriormente.
 */
- (IBAction)pauseDownload:(UIBarButtonItem *)sender
{
    [self.downloadTask cancelByProducingResumeData:^(NSData *resumeData) {
        /*
         * Só salva se existe algum dado já baixado
         */
        if (resumeData) {
            taskResumeData = [[NSData alloc] initWithData:resumeData];
        }
    }];
    
    /*
     * Configura os botões da toolbar
     */
    [self configureButtonsOnPauseOrStopDownload];
}

/*
 * Este método é responsável por tratar o toque no botão
 * no botão de stopDownloadButton
 */
- (IBAction)stopDownload:(UIBarButtonItem *)sender {
    [self.downloadTask cancel];
    
    /*
     * Como o download foi cancelado, deveremos
     * atribuir nil a task e aos dados de backup
     * caso a task tenha sido pausada.
     *
     * Deve-se também configurar a toolbar para
     * para seu estado
     */
    [self setUpDownloadTask];
    [self configureButtonsOnPauseOrStopDownload];
    
}

#pragma mark Métodos de Rede
/*
 * Este método cria uma nova NSURLSession e a configura
 * Usamos dispatch_once para evitar qualquer condição de 
 * corrida durante a criação de nosso objeto sessão, pois
 * este será manipulado por mais de uma thread.
 *
 * Para entender melhor, consulte: https://mikeash.com/pyblog/friday-qa-2009-10-02-care-and-feeding-of-singletons.html
 */
- (NSURLSession *)backgroundSession
{
    static NSURLSession *session = nil;
    static dispatch_once_t onceToken;
    
    dispatch_once(&onceToken, ^{
        
        // Criação do objeto de configurações da sessão
        NSURLSessionConfiguration *config = [NSURLSessionConfiguration backgroundSessionConfiguration:@"br.ifce.edu.bepid.DownloadTaskBackgroundSample"];
        
        // Define a quantidade máxima de conexões HTTP para esta conexão
        config.HTTPMaximumConnectionsPerHost = 5;
        
        //Cria a sessão e define que a classe ViewController implementa o NSURLSessionDelegate
        session = [NSURLSession sessionWithConfiguration:config delegate:self delegateQueue:nil];
    });
    
    return session;
}

/*
 * Este é um método do protocolo do NSURLSessionDownloadDelegate 
 * e tem a função de informar periodicamente sobre o progresso
 * de um download.
 */
- (void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didWriteData:(int64_t)bytesWritten totalBytesWritten:(int64_t)totalBytesWritten totalBytesExpectedToWrite:(int64_t)totalBytesExpectedToWrite
{
    // verifica se esta task é a que temos interesse
    if (downloadTask == self.downloadTask)
    {
        //Calcula o progresso
        double progress = (double) totalBytesWritten / (double) totalBytesExpectedToWrite;
        
        /*
         * Todos os componentes gráficos devem ser atualizados
         * utilizando-se a thread principal, pois é ela quem 
         * lida com os componentes gráficos. 
         * dispatch_async submente, assincronamente, a execução
         * de um bloco de código por uma dada thread (neste caso, a thread principal).
         */
        dispatch_async(dispatch_get_main_queue(), ^{
            self.progressView.progress = progress;
        });
    }
}

/*
 * Este é um método do protocolo do NSURLSessionDownloadDelegate
 * e tem a função de realizar algum processamento ao final
 * de um download.
 *
 * Aqui, ele copiará o PDF baixado do local onde ele se localiza no
 * sistema de arquivos e o porá na pasta de Documents do Download.
 */
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didFinishDownloadingToURL:(NSURL *)downloadURL
{
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSArray *URLs = [fileManager URLsForDirectory:NSDocumentDirectory inDomains:NSUserDomainMask];
    NSURL *documentsDirectory = [URLs firstObject];
    
    NSURL *originalURL = [[downloadTask originalRequest] URL];
    NSURL *destinationURL = [documentsDirectory URLByAppendingPathComponent:[originalURL lastPathComponent]];
    NSError *errorCopy;
    
    //remove se houver um arquivo com o mesmo nome.
    [fileManager removeItemAtURL:destinationURL error:NULL];
    
    BOOL success = [fileManager copyItemAtURL:downloadURL toURL:destinationURL error:&errorCopy];
    
    /*
     * Em caso de sucesso, exibiremos o PDF baixado 
     * em um UIDocumentInteractionController
     * para isto utilizaremos dispatch_async para 
     * solicitar que a thread principal para mostrar
     * o referido controller.
     */
    if (success) {
        dispatch_async(dispatch_get_main_queue(), ^{
            self.documentInteractionController = [UIDocumentInteractionController interactionControllerWithURL:destinationURL];
            
            [self.documentInteractionController setDelegate:self];
            [self.documentInteractionController presentPreviewAnimated:YES];
            self.progressView.hidden = YES;
        });
    }
    else{
        NSLog(@"Error during the copy: %@", [errorCopy localizedDescription]);
    }
    
}

/*
 * Este método não faz nada. Apenas consta aqui por ser exigido
 * para esta implementação.
 */
-(void)URLSession:(NSURLSession *)session downloadTask:(NSURLSessionDownloadTask *)downloadTask didResumeAtOffset:(int64_t)fileOffset expectedTotalBytes:(int64_t)expectedTotalBytes
{
}

/*
 * Este método é chamado quando uma task é 
 * finalizada. Utilizamo-o para atualizar o valor do 
 * do progressView.
 */
- (void)URLSession:(NSURLSession *)session task:(NSURLSessionTask *)task didCompleteWithError:(NSError *)error {
    
    if (error == nil) {
        NSLog(@"Task: %@ completed successfully", task);
    } else {
        NSLog(@"Task: %@ completed with error: %@", task, [error localizedDescription]);
    }
    
    double progress = (double)task.countOfBytesReceived / (double)task.countOfBytesExpectedToReceive;
  
    dispatch_async(dispatch_get_main_queue(), ^{
        self.progressView.progress = progress;
    });
}

/*
 * Este método é chamado quando o aplicativo
 * executa em background. Ele é responsavel por 
 * exibir uma LocalNotification e atualizar o badge 
 * do ícone do aplicativo.
 */
- (void)URLSessionDidFinishEventsForBackgroundURLSession:(NSURLSession *)session
{
    AppDelegate *appDelegate = (AppDelegate *)[[UIApplication sharedApplication] delegate];
    if (appDelegate.backgroundSessionCompletionHandler)
    {
        void (^completionHandler)() = appDelegate.backgroundSessionCompletionHandler;
        appDelegate.backgroundSessionCompletionHandler = nil;
        completionHandler();
    }
    
    NSLog(@"All tasks are finished");
}

#pragma mark Apresentação de PDF

- (UIViewController *) documentInteractionControllerViewControllerForPreview: (UIDocumentInteractionController *) controller
{
    [self setUpDownloadTask];
    [self configureButtonsOnPauseOrStopDownload];
    
    return self;
}
@end
