//
//  MainViewController.m
//  Demo-动态选择列表
//
//  Created by Sun on 16/3/8.
//
//

#import "MainViewController.h"
#import "UIView+Frame.h"

#define mScreenWidth     [UIScreen mainScreen].bounds.size.width
#define mScreenHeight    [UIScreen mainScreen].bounds.size.height
#define arrowBtnW        25

@interface ChooseContentCell : UICollectionViewCell

@property(nonatomic,copy) NSString *title;
@property(nonatomic,strong) UILabel *titleLabel;
/** 标签下边的标示线 */
@property(nonatomic,strong) UIView *bottomLine;

@end

@implementation ChooseContentCell

-(instancetype)initWithFrame:(CGRect)frame{
    if (self =[super initWithFrame:frame]) {
        UILabel *lab = [[UILabel alloc]initWithFrame:CGRectMake(10, 10, 30, 30)];
        lab.font = [UIFont systemFontOfSize:14];
        lab.textColor = [UIColor lightTextColor];
        [self.contentView addSubview:lab];
        self.titleLabel = lab;
        
        UIView *lineView = [[UIView alloc]initWithFrame:CGRectMake(self.titleLabel.left - 6, lab.bottom+2, self.titleLabel.width + 10, 2)];
        lineView.backgroundColor = [UIColor orangeColor];
        [self.contentView addSubview:lineView];
        lineView.hidden = YES;
        self.bottomLine = lineView;
    }
    return self;
}

-(void)setTitle:(NSString *)title{
    _title = title;
    self.titleLabel.text = title;
    [self.titleLabel setTextColor:[UIColor blackColor]];
    [self.titleLabel sizeToFit];
    //需在此处设置item标签线的位置
    self.bottomLine.top = self.titleLabel.bottom+5;
    self.bottomLine.width = self.titleLabel.width+10;
}

@end


@interface MainViewController ()<UICollectionViewDelegate,UICollectionViewDataSource,UICollectionViewDelegateFlowLayout>{
    UICollectionView *_collectionView;
    UIView *_testView;
    BOOL _testOpened;
    UIButton *_testBtn;
}

@property(nonatomic,strong) UIView *baseView; //左右滑的背景view
@property(nonatomic,strong) UIView *chooseView;//点击按钮后的全部item背景
@property(nonatomic,assign) BOOL isOpen; //列表是否展开，默认为NO
@property(nonatomic,strong) UIButton *arrowBtn;
@property(nonatomic,strong) NSMutableArray *labelArr; //标签名称数组
@property(nonatomic,strong) UILabel *tipViewLabel; //baseView上的标签，点击按钮collectionview会切换为该标签
@property(nonatomic,assign) NSInteger selectedIndex; //被选择的标签位置
@property(nonatomic,strong) UIButton *currentSelectedBtn; //当前选择的btn

@end

@implementation MainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor whiteColor];
    
    self.labelArr = [NSMutableArray array];
    [self setUpLabelArray];
    
    [self setUpChooseView];
    
}

-(void)setUpLabelArray{
    NSMutableArray *dataArr = [NSMutableArray arrayWithObjects:@"新闻",@"搞个大新闻",@"财经人",@"校园大咖",@"政治",@"图片",@"社会",@"评论",@"音乐",@"军事",@"航空",@"公益", nil];
    self.labelArr = dataArr;
}

-(void)setUpChooseView{
    UIView *baseBackView = [[UIView alloc]initWithFrame:CGRectMake(0, 50, mScreenWidth, 50)];
    baseBackView.backgroundColor = [UIColor whiteColor];
    [self.view addSubview:baseBackView];
    self.baseView = baseBackView;
    
    /** baseView的边框 */
    UIView *boderViewUp = [[UIView alloc]initWithFrame:CGRectMake(0, 0, mScreenWidth, 1)];
    boderViewUp.backgroundColor = [UIColor colorWithRed:215/255.0 green:214/255.0 blue:215/255.0 alpha:1];
    [self.baseView addSubview:boderViewUp];
    UIView *boderViewDown = [[UIView alloc]initWithFrame:CGRectMake(0, self.baseView.height-1, mScreenWidth, 1)];
    boderViewDown.backgroundColor = [UIColor colorWithRed:215/255.0 green:214/255.0 blue:215/255.0 alpha:1];
    [self.baseView addSubview:boderViewDown];
    
    /** 设置布局 */
    UICollectionViewFlowLayout *flowLayout = [[UICollectionViewFlowLayout alloc]init];
    flowLayout.scrollDirection = UICollectionViewScrollDirectionHorizontal;
    //行间距(最小值)
    flowLayout.minimumLineSpacing = 0;
    //item间距(最小值)
    flowLayout.minimumInteritemSpacing = 0;
    //item大小
    flowLayout.itemSize = CGSizeMake(60, 39);
    
    _collectionView = [[UICollectionView alloc]initWithFrame:CGRectMake(10, 5, mScreenWidth-arrowBtnW-10, 39) collectionViewLayout:flowLayout];
    _collectionView.delegate = self;
    _collectionView.dataSource = self;
    _collectionView.backgroundColor = [UIColor whiteColor];
    _collectionView.showsHorizontalScrollIndicator = NO;
    [_collectionView registerClass:[ChooseContentCell class] forCellWithReuseIdentifier:@"chooseContentCellIdentifier"];
    [self.baseView addSubview:_collectionView];
    
    UIButton *downBtn = [UIButton buttonWithType:UIButtonTypeCustom];
    downBtn.frame = CGRectMake(_collectionView.right+5, 10, arrowBtnW, arrowBtnW);
    [downBtn setImage:[UIImage imageNamed:@"ic_down"] forState:UIControlStateNormal];
    [downBtn sizeToFit];
    [downBtn addTarget:self action:@selector(clickTheArrowBtn:) forControlEvents:UIControlEventTouchUpInside];
    [self.baseView addSubview:downBtn];
    self.arrowBtn = downBtn;
    
    UIView *chooView = [[UIView alloc]initWithFrame:CGRectMake(0, self.baseView.bottom+1, mScreenWidth, 0.1)];
    chooView.backgroundColor = [UIColor colorWithRed:242/255.0 green:242/255.0 blue:242/255.0 alpha:1];
    [self.view addSubview:chooView];
    self.chooseView = chooView;
    
    UILabel *tipLab = [[UILabel alloc]initWithFrame:_collectionView.frame];
    tipLab.backgroundColor = [UIColor whiteColor];
    tipLab.font = [UIFont systemFontOfSize:14.0f];
    tipLab.text = @"切换内容标签";
    tipLab.hidden = YES;
    self.tipViewLabel = tipLab;
    [self.baseView addSubview:tipLab];
}

-(void)clickTheArrowBtn:(UIButton *)arrowBtn{
    if (!self.isOpen) {
        //闭合
        self.tipViewLabel.hidden = NO;
        [UIView animateWithDuration:0.3f animations:^{
            self.chooseView.height = ((self.labelArr.count - 1) / 3 + 1) * 50 ;
        } completion:^(BOOL finished) {
            [self setUpChooseViewContent:self.labelArr];
            
        }];
    } else { //展开的
        self.tipViewLabel.hidden = YES;
        [self deleteAllItems];
        [UIView animateWithDuration:0.3f animations:^{
            self.chooseView.height = 0.1;
        } completion:^(BOOL finished) {
            
        }];
    }
    self.isOpen = !self.isOpen;
    //在现有旋转角度的基础上再旋转 M_PI度
    arrowBtn.transform = CGAffineTransformRotate(arrowBtn.transform, M_PI);
}

/** 往下拉表添加元素 */
-(void)setUpChooseViewContent:(NSMutableArray *)itemArr{
    if (self.chooseView.subviews.count > 0)return;
    //每行数目,也就是列数
    int numIndex = 3;
    CGFloat itemInChooseviewW = 80;
    CGFloat itemInChooseviewH = 30;
    CGFloat itemInChooseviewX = (mScreenWidth-numIndex*itemInChooseviewW)/(numIndex+1);
    
    for (int i=0; i<itemArr.count; i++) {
        int rowIndex = i/numIndex; //行号
        int columuIndex = i%numIndex; //列号
        
        UIButton *itemLab = [UIButton buttonWithType:UIButtonTypeCustom];
        itemLab.frame = CGRectMake(itemInChooseviewX+(itemInChooseviewX+itemInChooseviewW)*columuIndex, 10+(itemInChooseviewH+20)*rowIndex, itemInChooseviewW, itemInChooseviewH);
        [itemLab setTitle:[itemArr objectAtIndex:i] forState:UIControlStateNormal];
        [itemLab setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
        itemLab.titleLabel.font = [UIFont systemFontOfSize:14.0];
        
        UIImage *grayImg = [UIImage imageNamed:@"grayBtn"];
        UIImage *highLightImg = [UIImage imageNamed:@"highligtBtn"];
        [itemLab setBackgroundImage:grayImg forState:UIControlStateNormal];
        [itemLab setBackgroundImage:highLightImg forState:UIControlStateSelected];
        [itemLab addTarget:self action:@selector(clickTheItemBtn:) forControlEvents:UIControlEventTouchUpInside];
        itemLab.tag = i;
        [self.chooseView addSubview:itemLab];
        
        if (i==self.selectedIndex) {
            itemLab.selected = YES;
            self.currentSelectedBtn = itemLab;
        }
    }
}

/** 从下拉表删除元素 */
-(void)deleteAllItems{
    for (UIView *view in [self.chooseView subviews]) {
        [view removeFromSuperview];
    }
}

-(void)clickTheItemBtn:(UIButton *)itemBtn{
    if (itemBtn.tag == self.selectedIndex) {
        return;
    }
    self.currentSelectedBtn.selected = NO;
    itemBtn.selected = YES;
    self.currentSelectedBtn = itemBtn;
    
    [self clickTheArrowBtn:self.arrowBtn];
    [self collectionView:_collectionView didSelectItemAtIndexPath:[NSIndexPath indexPathForItem:itemBtn.tag inSection:0]];
    self.selectedIndex = itemBtn.tag;
}

#pragma mark - UICollectionView delegate
-(NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section{
    if (self.labelArr.count) {
        return self.labelArr.count;
    } else {
        return 1;
    }
}

-(UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath{
    NSString *title = [self.labelArr objectAtIndex:indexPath.item];
    //此处identifier需要与定义cell的相同，否则报错
    ChooseContentCell *chooseCell = [collectionView dequeueReusableCellWithReuseIdentifier:@"chooseContentCellIdentifier" forIndexPath:indexPath];
    chooseCell.title = title;
    chooseCell.bottomLine.hidden = indexPath.item == self.selectedIndex ? NO:YES;
    return chooseCell;
}

/** 设置各个item大小 */
-(CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout *)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath{
    NSString *title = [self.labelArr objectAtIndex:indexPath.item];
    return CGSizeMake(title.length*15+30, 39);
}

-(void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath{
    if (self.selectedIndex == indexPath.item) {
        return;
    }

    ChooseContentCell *lastCell = (ChooseContentCell *)[_collectionView cellForItemAtIndexPath:[NSIndexPath indexPathForItem:self.selectedIndex inSection:0]];
    lastCell.bottomLine.hidden = YES;
    ChooseContentCell *currentCell = (ChooseContentCell *)[_collectionView cellForItemAtIndexPath:indexPath];
    currentCell.bottomLine.hidden = NO;
    
    self.selectedIndex = indexPath.item;
    [_collectionView scrollToItemAtIndexPath:indexPath atScrollPosition:UICollectionViewScrollPositionCenteredHorizontally animated:YES];
    
}



@end
