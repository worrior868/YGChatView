//
//  YFHistoryVC.m
//  YF002
//
//  Created by Mushroom on 5/31/15.
//  Copyright (c) 2015 Mushroom. All rights reserved.
//

#import "ViewController.h"
#import <UIKit/UIKit.h>

#import "AKPickerView.h"

#define screenWidth [UIScreen mainScreen].bounds.size.width
#define screenHeight [UIScreen mainScreen].bounds.size.height

#define kDropDownListTag 1000

#define  selfDefineColor1 [UIColor colorWithRed:187.0/255 green:135.0/255 blue:87.0/255 alpha:0.8]
//主色调
#define  selfDefineColor2 [UIColor colorWithRed:116.0/255 green:201.0/255 blue:184.0/255 alpha:1]


@interface ViewController ()  <UIScrollViewDelegate,AKPickerViewDataSource, AKPickerViewDelegate>
{
    
    NSMutableDictionary *addressDict;   //地址选择字典
    NSMutableDictionary *areaDic;
    NSArray *province;
    NSArray *city;
    NSArray *district;
    
    NSString *selectedProvince;
    NSString *selectedCity;
    NSString *selectedArea;
    
    UISegmentedControl *segmentControl;
    chatView *chat;
    UIView *dayView;
    UIView *dateView;
    UILabel *dateLab;
    
    
    int goY;
    int goW;
    int goM;
}
@property (nonatomic,strong) UIView *chatOnView;
@property (nonatomic,strong) UILabel *drugLab;

@property (nonatomic, strong) AKPickerView *pickerView;
@property (nonatomic, strong) NSMutableArray *titles;
@property (weak, nonatomic) IBOutlet UIView *drugView;
@property (weak, nonatomic) IBOutlet UIView *pickViewBackground;

//曲线的数量
@property (nonatomic,assign) NSInteger curveCount;


//图表的左右两侧数据
@property (nonatomic,assign) NSInteger leftMaxValue;
@property (nonatomic,assign) NSInteger rightMaxValue;

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    //   创建滚动视图
    _scrollView.directionalLockEnabled = YES;
    //只能一个方向滑动
    _scrollView.pagingEnabled = NO;
    //是否翻页
    _scrollView.showsVerticalScrollIndicator =YES;
    //垂直方向的滚动指示
    _scrollView.indicatorStyle = UIScrollViewIndicatorStyleWhite;
    //滚动指示的风格
    _scrollView.showsHorizontalScrollIndicator = NO;
    //水平方向的滚动指示
    _scrollView.delegate = self;
    _scrollView.backgroundColor = [UIColor whiteColor];
    CGSize newSize = CGSizeMake(self.view.frame.size.width, 600);
    [_scrollView setContentSize:newSize];
    //图表所在的视图
    _chatOnView = [[UIView alloc] init];
    _chatOnView.frame = CGRectMake(0, 100, screenWidth, 350);
    _chatOnView.backgroundColor = selfDefineColor2;
    [_scrollView addSubview:_chatOnView];
    
    //读取plist,生成第一级别的dictionary
    NSString *plistPath;
    NSString *rootPath = [NSSearchPathForDirectoriesInDomains(NSDocumentDirectory,NSUserDomainMask, YES) objectAtIndex:0];
    plistPath = [rootPath stringByAppendingPathComponent:@"treatHistory.plist"];
    if (![[NSFileManager defaultManager] fileExistsAtPath:plistPath]) {
        plistPath =  [[NSBundle mainBundle] pathForResource:@"treatHistory" ofType:@"plist"];
    }
    _recordArray = [[NSMutableArray alloc] initWithContentsOfFile:plistPath];
    
    
    //配置分段开关
    segmentControl = [[UISegmentedControl alloc]initWithFrame:CGRectMake(15, 15, 290, 30)];
    [segmentControl insertSegmentWithTitle:@"周" atIndex:0 animated:YES];
    [segmentControl insertSegmentWithTitle:@"月" atIndex:1 animated:YES];
    [segmentControl insertSegmentWithTitle:@"年" atIndex:2 animated:YES];
    [segmentControl setSelectedSegmentIndex:0];
    
    [segmentControl setTintColor: [UIColor colorWithRed:133.0/255 green:211.0/255 blue:198.0/255 alpha:1.0]];
    [segmentControl setAlpha:1.0f];
    [segmentControl setTitleTextAttributes:[NSDictionary dictionaryWithObjectsAndKeys:[UIFont systemFontOfSize:15],NSFontAttributeName, nil] forState:UIControlStateNormal];
    [self.scrollView addSubview:segmentControl];
    
    [segmentControl addTarget:self action:@selector(controlPress:) forControlEvents:UIControlEventValueChanged];
    [self controlPressOne];
    
    
    //配置药物选择部分
    _drugView.frame = CGRectMake(0, 15, 320, 30);
    [_chatOnView addSubview:_drugView];
    //设置view的圆角
    _pickViewBackground.layer.cornerRadius = 5.0;
    
    self.pickerView = [[AKPickerView alloc] initWithFrame:CGRectMake(93, 5, 200, 50)];
    self.pickerView.delegate = self;
    self.pickerView.dataSource = self;
    self.pickerView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    [self.view addSubview:self.pickerView];
    self.pickerView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:13];
    self.pickerView.textColor = [UIColor colorWithRed:180.0/255 green:180.0/255 blue:180.0/255 alpha:120.0/255];
    self.pickerView.highlightedFont = [UIFont fontWithName:@"HelveticaNeue" size:14];
    self.pickerView.highlightedTextColor = [UIColor whiteColor];
    self.pickerView.interitemSpacing = 8;
    self.pickerView.maskDisabled = true;
    self.titles = @[@"扶他林",
                    @"布洛芬",
                    @"保泰松",
                    @"其他",@"无",];
    
    [self.pickerView reloadData];
    [_pickerView selectItem:1 animated:NO];
    [_chatOnView addSubview:_pickerView];
    
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}





#pragma mark -  设置日期UI选择的初始化
- (void)initDateView
{
    if(!dateView){
        dateView = [[UIView alloc]initWithFrame:CGRectMake(segmentControl.frame.origin.x+segmentControl.frame.origin.x-20, segmentControl.frame.origin.y+segmentControl.frame.size.height+8, 290, 35)];
        dateView.opaque = NO;
        [self.view addSubview:dateView];
        //中间日期显示初始化
        dateLab = [[UILabel alloc]initWithFrame:CGRectMake(segmentControl.frame.origin.x+segmentControl.frame.origin.x+20, 7, dateView.frame.size.width-100, 25)];
        [dateLab setBackgroundColor:[UIColor clearColor]];
        [dateLab setTextColor:[UIColor colorWithRed:150.0/255 green:150.0/255 blue:150.0/255 alpha:1.0]];
        [dateLab setFont:[UIFont fontWithName:@"Arial" size:17]];
        [dateLab setTextAlignment:NSTextAlignmentCenter];
        [dateView addSubview:dateLab];
        //左边（日期减少）按钮初始化
        UIImage* image1 =[UIImage imageNamed:@"leftarrow"];
        UIButton* btn1 = [UIButton buttonWithType:UIButtonTypeCustom];
        btn1.frame = CGRectMake(10, 9, 20, 20);
        btn1.tag = 0;
        btn1.backgroundColor = [UIColor blackColor];
        [btn1 setBackgroundImage:image1 forState:UIControlStateNormal];
        [btn1 addTarget:self action:@selector(goOrBack:) forControlEvents:UIControlEventTouchUpInside];
        [dateView addSubview:btn1];
        //右边(日期增加)按钮初始化
        UIImage* image2 =[UIImage imageNamed:@"rightarrow"];
        UIButton* btn2 = [UIButton buttonWithType:UIButtonTypeCustom];
        btn2.backgroundColor = [UIColor blackColor];

        btn2.frame = CGRectMake(260, 9, 20,20);
        btn2.tag = 1;
        [btn2 setBackgroundImage:image2 forState:UIControlStateNormal];
        [btn2 addTarget:self action:@selector(goOrBack:) forControlEvents:UIControlEventTouchUpInside];
        [dateView addSubview:btn2];
        
        
    }
    
    
    
}
#pragma mark 左右按钮选择不同日期
- (void)goOrBack:(UIButton* )btn
{
    for(id obj in chat.subviews){
        if([obj isKindOfClass:[InfoView class]]){
            [obj removeFromSuperview];}
    }
    if(chat.lines){
        [chat.lines removeAllObjects];
        [chat.points removeAllObjects];
        [dayView removeFromSuperview];
        dayView = nil;
        [chat setNeedsDisplay];
    }
    if(btn.tag==1){
        switch ([segmentControl selectedSegmentIndex]) {
            case 0:{
                goW++;
                [dateLab setText:[self returnWeekDayWithD:[self getCurrentTimeWith:week] W:goW]];
                [self readyDrawLineWithTip:0];
                break;
            }
            case 1:{
                goM++;
                [dateLab setText:[self returnMonthDayWithM:[self getCurrentTimeWith:month] andDay:[self getCurrentTimeWith:day] W:goM]];
                [self readyDrawLineWithTip:1];
                break;
            }
            case 2:{
                goY++;
                [dateLab setText:[self returnCurrentYear:goY]];
                [self readyDrawLineWithTip:2];
                break;
            }
            default:
                break;
        }
    }else{
        
        switch ([segmentControl selectedSegmentIndex]) {
            case 0:{
                goW--;
                [dateLab setText:[self returnWeekDayWithD:[self getCurrentTimeWith:week] W:goW]];
                [self readyDrawLineWithTip:0];
                break;
            }
            case 1:{
                goM--;
                [dateLab setText:[self returnMonthDayWithM:[self getCurrentTimeWith:month] andDay:[self getCurrentTimeWith:day] W:goM]];
                [self readyDrawLineWithTip:1];
                break;
            }
            default:{
                goY--;
                [dateLab setText:[self returnCurrentYear:goY]];
                [self readyDrawLineWithTip:2];
                break;
            }
        }
    }
}
//获取当前年月日，星期
- (int)getCurrentTimeWith:(State)state
{
    NSDate* date = [NSDate date];
    NSCalendar* calendar = [NSCalendar currentCalendar];
    NSDateComponents* comps = [calendar components:(NSCalendarUnitYear|NSCalendarUnitMonth|NSCalendarUnitDay|NSCalendarUnitWeekday) fromDate:date];
    switch (state) {
        case year:{
            return (int)[comps year];
        }
            break;
        case month:{
            return (int)[comps month];
            break;
        }
        case day:{
            return (int)[comps day];
            break;
        }
        case week:{
            return (int)[comps weekday]-1>0?(int)[comps weekday]-1:7;
            break;
        }
        default:
            break;
    }
}

- (NSString* )returnCurrentYear:(int)d
{
    NSDate* date = [NSDate date];
    NSDateFormatter* formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"YYYY"];
    NSString* str = [formatter stringFromDate:date];
    
    return [NSString stringWithFormat:@"%d年",[str intValue]+d];
}

//返回本周的日期范围
- (NSString* )returnWeekDayWithD:(int)w W:(int)n
{
    NSDate* date1 = [NSDate dateWithTimeIntervalSinceNow:60*60*24*(n*7-w+1)];
    NSDate* date2 = [NSDate dateWithTimeIntervalSinceNow:60*60*24*(n*7-w+7)];
    NSDateFormatter* formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"MM-dd"];
    NSString* str1 = [formatter stringFromDate:date1];
    NSString* str2 = [formatter stringFromDate:date2];
    return [NSString stringWithFormat:@"%@月%@日 - %@月%@日", [[str1 componentsSeparatedByString:@"-"] objectAtIndex:0], [[str1 componentsSeparatedByString:@"-"] objectAtIndex:1], [[str2 componentsSeparatedByString:@"-"] objectAtIndex:0], [[str2 componentsSeparatedByString:@"-"] objectAtIndex:1]];
}

int backDaysM(int m){
    switch (m) {
        case 2:{
            return 28;
            break;
        }
        case 4:
        case 6:
        case 9:
        case 11:{
            return 30;
            break;
        }
        default:
            return 31;
            break;
    }
    
}

- (int)backDaysWithM:(int)m andW:(int)w
{
    int days=0;
    if(w>0){
        for(int i=1; i<=w; i++){
            m++;
            if(m>12)m=1;
            days+=backDaysM(m);
        }
    }else if(w<0){
        for(int i=1; i<=(-w); i++){
            m--;
            if(m<=0)m=12;
            days-=backDaysM(m);
        }
    }else{
        days = 0;
    }
    return days;
}

- (int)backaDaysWithM:(int)m andW:(int)w
{
    int days=0;
    if(w>0){
        for(int i=0; i<w; i++){
            if(i!=0)m++;
            if(m>12)m=1;
            days+=backDaysM(m);
        }
    }else if(w<0){
        for(int i=0; i<(-w); i++){
            if(i!=0)m--;
            if(m<=0){
                m=12;
            }
            days-=backDaysM(m);
        }
    }else{
        days = 0;
    }
    return days;
}

#pragma mark  返回当月的日期范围
- (NSString* )returnMonthDayWithM:(int)m andDay:(int)d W:(int)w
{
    int day=backDaysM(m);
    int days=0;
    int days2=0;
    if(w>0){
        days = [self backaDaysWithM:m andW:w];
        days2 = [self backDaysWithM:m andW:w];
    }else{
        days = [self backDaysWithM:m andW:w];
        days2 = [self backaDaysWithM:m andW:w];
    }
    
    NSLog(@"%d-%d", days, days2);
    NSDate* date1 = [NSDate dateWithTimeIntervalSinceNow:60*60*24*(days-d+1)];
    NSDate* date2 = [NSDate dateWithTimeIntervalSinceNow:60*60*24*(days2+day-d)];
    NSDateFormatter* formatter = [[NSDateFormatter alloc]init];
    [formatter setDateFormat:@"MM-dd"];
    NSString* str1 = [formatter stringFromDate:date1];
    NSString* str2 = [formatter stringFromDate:date2];
    return [NSString stringWithFormat:@"%@月%@日 - %@月%@日", [[str1 componentsSeparatedByString:@"-"] objectAtIndex:0], [[str1 componentsSeparatedByString:@"-"] objectAtIndex:1], [[str2 componentsSeparatedByString:@"-"] objectAtIndex:0], [[str2 componentsSeparatedByString:@"-"] objectAtIndex:1]];
}

#pragma mark  根据周月年返回dateView日期的值
- (NSString* )returnCurrentTimeStrWithTip:(int)tip
{
    switch (tip) {
        case 0:{
            return [self returnWeekDayWithD:[self getCurrentTimeWith:week] W:0];
            break;}
        case 1:{
            return [self returnMonthDayWithM:[self getCurrentTimeWith:month] andDay:[self getCurrentTimeWith:day] W:0];
            break; }
        default:
            return [self returnCurrentYear:0];
        break;}
}
#pragma mark  设置曲线的数量
- (NSArray* )returnPointXandYWithTip:(int)tip
{
    
    if (_curveCount == 2) {
        //创建第一条线的点
        NSMutableArray *aPoints = [[NSMutableArray alloc]init];
        //创建第二条线的点
        NSMutableArray *bPoints = [[NSMutableArray alloc] init];
        //根据划分几个网格来设置点数据
        //int gap = chat.frame.size.width/([self rePointCountWithTip:tip]-2);
        int gap = chat.frame.size.width/([self rePointCountWithTip:tip]-2);
        if(([self rePointCountWithTip:tip]-2)*gap>=250){
            gap-=2;
        }
        for(int i=0; i<[self rePointCountWithTip:tip]-1; i++){
            //随机产生画曲线所需的点
            CGPoint point1 =CGPointMake(1+gap*i, arc4random()%180);
            [aPoints addObject:[NSValue valueWithCGPoint:point1]];
            CGPoint point2 =CGPointMake(1+gap*i, arc4random()%180+20);
            [bPoints addObject:[NSValue valueWithCGPoint:point2]];
        }
        return [NSArray arrayWithObjects:aPoints,bPoints, nil];
    } else {
        //创建第一条线的点
        NSMutableArray *aPoints = [[NSMutableArray alloc]init];
        
        //根据划分几个网格来设置点数据
        //int gap = chat.frame.size.width/([self rePointCountWithTip:tip]-2);
        int gap = chat.frame.size.width/([self rePointCountWithTip:tip]-2);
        if(([self rePointCountWithTip:tip]-2)*gap>=250){
            gap-=2;
        }
        for(int i=0; i<[self rePointCountWithTip:tip]-1; i++){
            //随机产生画曲线所需的点
            CGPoint point1 =CGPointMake(1+gap*i, arc4random()%180);
            [aPoints addObject:[NSValue valueWithCGPoint:point1]];

        }
        return [NSArray arrayWithObjects:aPoints, nil];
    }
   
    
    
}

#pragma mark  根据周月年画表格线，纵横坐标刻度值
- (void)readyDrawLineWithTip:(int)tip
{
    [self initDateView];
    if(!chat){
        //曲线位置所在视图
        chat = [[chatView alloc]initWithFrame:CGRectMake(40, 70, 250, 210)];
        [chat setBackgroundColor:[UIColor clearColor]];
        chat.opaque= NO;
        [_chatOnView addSubview:chat];
    }
    if(!dayView){
        //图表底部横坐标所在视图显示
        dayView = [[UIView alloc]initWithFrame:CGRectMake(0, chat.frame.origin.y+chat.frame.size.height, [[UIScreen mainScreen] bounds].size.width, 10)];
        dayView.opaque = NO;
        [_chatOnView addSubview:dayView];
    }
    if(!chat.lines.count){
        // 1.图表纵向分割线以及时间刻度值
        //1.0 纵向线间距
        int gap = chat.frame.size.width/([self reLineCountWithTip:tip]-2);
        //1.1循环划线
        for(int i=0; i<[self reLineCountWithTip:tip]; i++){
            Line* line = [[Line alloc]init];
            if(i!=[self reLineCountWithTip:tip]-1){
                //如果曲线条数位2 则画出右边的纵向线，否则不画
                if (i==0 ) {
                    line.firstPoint = CGPointMake(1+gap*i, 0);
                    line.secondPoint = CGPointMake(1+gap*i, 205);
                    
                }
                if (_curveCount == 2 && i== [self reLineCountWithTip:tip]-2) {
                    line.firstPoint = CGPointMake(1+gap*i, 0);
                    line.secondPoint = CGPointMake(1+gap*i, 205);
                    
                }


                
                //图表底部横坐标刻度位置
                UILabel *lab = [[UILabel alloc]initWithFrame:CGRectMake(25+gap*i, 5, 34, 10)];
                //图表底部横坐标刻度内容
                [lab setText:[self reWeeksWithDay:i UseTip:tip]];
                [lab setBackgroundColor:[UIColor clearColor]];
                //图表底部横坐标刻度颜色
                [lab setTextColor:[UIColor grayColor]];
                [lab setFont:[UIFont systemFontOfSize:11]];
                [dayView addSubview:lab];
            }else{
                line.firstPoint = CGPointMake(0, 205);
                line.secondPoint = CGPointMake(247, 205);
            }
            [chat.lines addObject:line];
        }
        
        int gap2 = chat.frame.size.width/([self rePointCountWithTip:tip]-2);
        if(([self rePointCountWithTip:tip]-2)*gap2>=250){
            gap2-=2;
        }
        chat.points = [[self returnPointXandYWithTip:tip] mutableCopy];
        
        //3.纵轴左边刻度数值
        // 3.0取出存储的plist历史纪录，按照日期排序；
        [self leftlabelChatView];
        //3.1与当前所在的label日期相比较，并且取得segment选取的index，
        // 3.2符合要求后加入新的数组，累加时间，有药物的话累加药物；
         
        for(int i=0; i<5; i++){
            UILabel* label = [[UILabel alloc]initWithFrame:CGRectMake(10, i*50-chat.frame.size.height-5, 30, 20)];
            [label setText:[NSString stringWithFormat:@"%d", 40-i*10]];
            [label setTextColor:[UIColor colorWithRed:120.0/255 green:120.0/255 blue:120.0/255 alpha:1.0]];
            [label setFont:[UIFont systemFontOfSize:11]];
            [label setTextAlignment:NSTextAlignmentCenter];
            [label setBackgroundColor:[UIColor clearColor]];
            [dayView addSubview:label];
        }
        //4.如果曲线条数为2，则设置纵轴右边药物刻度数值
        if (_curveCount == 2) {
            for(int i=0; i<5; i++){
                UILabel* label = [[UILabel alloc]initWithFrame:CGRectMake( 290,  i*50-chat.frame.size.height-5, 30, 20)];
                [label setText:[NSString stringWithFormat:@"%d", 20-i*5]];
                [label setTextColor:[UIColor blueColor ]];
                [label setFont:[UIFont systemFontOfSize:11]];
                [label setTextAlignment:NSTextAlignmentCenter];
                [label setBackgroundColor:[UIColor clearColor]];
                [dayView addSubview:label];
            }
         }
    }
    NSArray *lastPoint = [chat.points lastObject] ;
    NSLog(@"lastPoint is %@",lastPoint);
}
#pragma mark  图表左侧标签以及底部数组的值
-(void)leftlabelChatView{
    //当前选择的日期处理
    NSDate* date = [NSDate date];
    NSDateFormatter* formatter1 = [[NSDateFormatter alloc]init];
    [formatter1 setDateFormat:@"YYYY"];
    NSString* string0 = [formatter1 stringFromDate:date];
    
    NSString *string1=[dateLab.text substringWithRange:NSMakeRange(0, 2)];
    NSString *string2=[dateLab.text substringWithRange:NSMakeRange(3, 2)];
    NSString *string3 = [NSString stringWithFormat:@"%@%@%@",string0,string1,string2];
    NSDateFormatter* formatter2 = [[NSDateFormatter alloc]init];
    [formatter2 setDateFormat:@"YYYYMMDD"];
    NSDate *selectBeginDate =[formatter2 dateFromString:string3];
    //历史数据数组
    NSArray *history= [[NSArray alloc] init];
    
    switch ([segmentControl selectedSegmentIndex]) {
    case (0):{
        //历史日期处理
        NSInteger e;
        for (e=0; e<[history count]; e++) {
            //当前数组下的字典值
            NSDictionary *treatItem = [history objectAtIndex:e];
            NSString *treatDateStr= [treatItem objectForKey:@"treatDate"];
            NSString *treatDate1 = [treatDateStr substringWithRange:NSMakeRange(0, 8)];
            NSDate *treatDate = [formatter2 dateFromString:treatDate1];
             //
           if ([treatDate laterDate:selectBeginDate] ) {
                //初始化周的数组值
               NSMutableArray *weekData =[[NSMutableArray alloc]init];
               for(NSInteger p=0 ;p<week;p++){
               [weekData addObject:@"0"];
               }
               
                //计算历史中的值与选择的差距
                NSInteger timeInterval =(NSInteger)[treatDate timeIntervalSinceDate:selectBeginDate];
                NSInteger dayDistance = timeInterval/(24*60*60);
                //如果超出一周则推出
                if (dayDistance > week-1) {
                    break;}
                //取出周对应的数值
                NSString *dayValue =[weekData objectAtIndex:dayDistance];
                NSInteger currentValue = [dayValue integerValue];
                //取出历史字典中treatTime的值
                NSString *treatTime = [treatItem objectForKey:@"treatTime"];
                NSInteger treatTimeInt = [treatTime integerValue]*5;
                //累加出新的数值并更新到周的数组中
                NSInteger newValue =currentValue +treatTimeInt;
                NSString *newStr = [NSString stringWithFormat:@"%ld",(long)newValue];
                [weekData replaceObjectAtIndex:dayDistance withObject:newStr];
                
            }
            
            break;
            
        }
        
        break;}
    case (1):
    {}
        break;
    case (2):
    {}
        break;
        
}
}
//根据tip返回点数
- (int)rePointCountWithTip:(int)tip
{
    switch (tip) {
        case 0:{return 8;break;}
        case 1:{return 9;break;}
        default:{return 8;break;}
    }
}
//根据tip返回线的条数
- (int)reLineCountWithTip:(int)tip{
    switch (tip) {
        case 0:{return 8;break;}
        case 1:{return 9;break;}
        default:{return 8;break;}
    }
}

- (NSString* )reWeeksWithDay:(int)day UseTip:(int)tip
{
    if(tip==0){
        switch (day) {
            case 0:{return @"星期一";break;}
            case 1:{return @"星期二";break;}
            case 2:{return @"星期三";break;}
            case 3:{return @"星期四";break;}
            case 4:{return @"星期五";break;}
            case 5:{return @"星期六";break;}
            default:return @"星期日";break;}
    }else if(tip==1){
        switch (day) {
            case 0:{return @"1日";break;}
            case 1:{return @"4日";break;}
            case 2:{return @"8日";break;}
            case 3:{return @"12日";break;}
            case 4:{return @"16日";break;}
            case 5:{return @"20日";break;}
            case 6:{return @"24日";break;}
            default:return @"28日";break;}
    }else{
        switch (day) {case 0:{return @"1月";break;}
            case 1:{return @"2月";break;}
            case 2:{return @"4月";break;}
            case 3:{return @"6月";break;}
            case 4:{return @"8月";break;}
            case 5:{return @"10月";break;}
            default:return @"12月";break;}
    }
}

//初始化时第一次使用周显示
- (void)controlPressOne
{
    for(id obj in chat.subviews){
        if([obj isKindOfClass:[InfoView class]]){
            [obj removeFromSuperview];
        }
    }
    if(chat.lines){
        [chat.lines removeAllObjects];
        [chat.points removeAllObjects];
        [dayView removeFromSuperview];
        dayView = nil;
        [chat setNeedsDisplay];
    }
    [self readyDrawLineWithTip:0];
    [dateLab setText:[self returnCurrentTimeStrWithTip:0]];
}
//按钮选择对应周月年
- (void)controlPress:(id)sender
{
    for(id obj in chat.subviews){
        if([obj isKindOfClass:[InfoView class]]){
            [obj removeFromSuperview];
        }
    }
    switch ([segmentControl selectedSegmentIndex]) {
            
        case 0:{
            if(chat.lines){
                [chat.lines removeAllObjects];
                [chat.points removeAllObjects];
               // [chat removeFromSuperview];
               // chat = nil;
                [dayView removeFromSuperview];
                dayView = nil;
                [chat setNeedsDisplay];
            }
            goY=0;goM=0;
            //分段周月年选择 此处选择周
            [self readyDrawLineWithTip:0];
            [dateLab setText:[self returnCurrentTimeStrWithTip:0]];
            NSLog(@"0");
            break;
        }
        case 1:{
            if(chat.lines){
                [chat.lines removeAllObjects];
                [chat.points removeAllObjects];
                [dayView removeFromSuperview];
                dayView = nil;
                [chat setNeedsDisplay];
            }
            goY=0;goW=0;
            [self readyDrawLineWithTip:1];
            [dateLab setText:[self returnCurrentTimeStrWithTip:1]];
            NSLog(@"1");
            break;
        }
        default:{
            if(chat.lines){
                [chat.lines removeAllObjects];
                [chat.points removeAllObjects];
                [dayView removeFromSuperview];
                dayView = nil;
                [chat setNeedsDisplay];
            }
            goY=0;goW=0;
            [self readyDrawLineWithTip:2];
            [dateLab setText:[self returnCurrentTimeStrWithTip:2]];
            NSLog(@"2");
            break;
        }
    }
}
/*
 - (void)drawLineWithCount
 {
 //    UIImageView *imageView1 = [[UIImageView alloc]initWithFrame:CGRectMake(100, 200, 10, 10)];
 //    [self.view addSubview:imageView1];
 //
 //    UIGraphicsBeginImageContext(imageView1.frame.size);   //开始画线
 //    [imageView1.image drawInRect:CGRectMake(0, 0, imageView1.frame.size.width, imageView1.frame.size.height)];
 //    CGContextSetLineCap(UIGraphicsGetCurrentContext(), kCGLineCapRound);  //设置线条终点形状
 //
 //    CGContextRef line = UIGraphicsGetCurrentContext();
 //    CGContextSetFillColorWithColor(line, [UIColor blueColor].CGColor);
 //    CGPoint p = CGPointMake(0, 0);
 //    CGContextFillEllipseInRect(line, CGRectMake(p.x, p.y, 15, 8));
 //    imageView1.image = UIGraphicsGetImageFromCurrentImageContext();
 }
 */


#pragma mark - UITableView Datasource

//- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
//    return 1;
//}
//
//- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
//    //    return section?2:4;
//    return 1;
//
//}
//
//
//- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
//    static NSString *cellIdentifier = @"TableViewCell";
//
//
//
//
//    return cell;
//}

//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath{
//    return 170;
//}


/*
 #pragma mark - Navigation
 
 // In a storyboard-based application, you will often want to do a little preparation before navigation
 - (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
 // Get the new view controller using [segue destinationViewController].
 // Pass the selected object to the new view controller.
 }
 */
#pragma mark - AKPickerViewDataSource

- (NSUInteger)numberOfItemsInPickerView:(AKPickerView *)pickerView
{
    return [self.titles count];
}

/*
 * AKPickerView now support images!
 *
 * Please comment '-pickerView:titleForItem:' entirely
 * and uncomment '-pickerView:imageForItem:' to see how it works.
 *
 */

- (NSString *)pickerView:(AKPickerView *)pickerView titleForItem:(NSInteger)item
{
    return self.titles[item];
}

/*
 - (UIImage *)pickerView:(AKPickerView *)pickerView imageForItem:(NSInteger)item
 {
	return [UIImage imageNamed:self.titles[item]];
 }
 */

#pragma mark - AKPickerViewDelegate

- (void)pickerView:(AKPickerView *)pickerView didSelectItem:(NSInteger)item
{
   
    if ([self.titles[item] isEqualToString:@"无"]) {
        _curveCount = 1;
        [self controlPress:nil];
    } else {
        _curveCount = 2;
         [self controlPress:nil];
    }
    [self controlPress:nil];
    
    NSLog(@"%@", self.titles[item]);
}


/*
 * Label Customization
 *
 * You can customize labels by their any properties (except font,)
 * and margin around text.
 * These methods are optional, and ignored when using images.
 *
 */

/*
 - (void)pickerView:(AKPickerView *)pickerView configureLabel:(UILabel *const)label forItem:(NSInteger)item
 {
	label.textColor = [UIColor lightGrayColor];
	label.highlightedTextColor = [UIColor whiteColor];
	label.backgroundColor = [UIColor colorWithHue:(float)item/(float)self.titles.count
 saturation:1.0
 brightness:1.0
 alpha:1.0];
 }
 */

/*
 - (CGSize)pickerView:(AKPickerView *)pickerView marginForItem:(NSInteger)item
 {
	return CGSizeMake(20, 20);
 }
 */
@end
