//
//  JXPagingView.m
//  JXPagingView
//
//  Created by jiaxin on 2018/8/27.
//  Copyright © 2018年 jiaxin. All rights reserved.
//

#import "JXPagingView.h"

@interface JXPagingView () <UITableViewDataSource, UITableViewDelegate, JXPagingListContainerViewDelegate>

@property (nonatomic, strong) JXPagingMainTableView *mainTableView;
@property (nonatomic, strong) JXPagingListContainerView *listContainerView;
@property (nonatomic, strong) UIScrollView *currentScrollingListView;

@end

@implementation JXPagingView

- (instancetype)initWithDelegate:(id<JXPagingViewDelegate>)delegate {
    self = [super initWithFrame:CGRectZero];
    if (self) {
        _delegate = delegate;
        [self initializeViews];
    }
    return self;
}

- (void)initializeViews {
    _mainTableView = [[JXPagingMainTableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];
    self.mainTableView.showsVerticalScrollIndicator = NO;
    self.mainTableView.showsHorizontalScrollIndicator = NO;
    self.mainTableView.separatorStyle = UITableViewCellSeparatorStyleNone;
    self.mainTableView.dataSource = self;
    self.mainTableView.delegate = self;
    self.mainTableView.tableHeaderView = [self.delegate tableHeaderViewInPagingView:self];
    [self.mainTableView registerClass:[UITableViewCell class] forCellReuseIdentifier:@"cell"];
    if (@available(iOS 11.0, *)) {
        self.mainTableView.contentInsetAdjustmentBehavior = UIScrollViewContentInsetAdjustmentNever;
    }
    [self addSubview:self.mainTableView];

    _listContainerView = [[JXPagingListContainerView alloc] initWithDelegate:self];
    self.listContainerView.mainTableView = self.mainTableView;

    [self configListViewDidScrollCallback];
}

- (void)layoutSubviews {
    [super layoutSubviews];

    self.mainTableView.frame = self.bounds;
}

- (void)reloadData {
    [self configListViewDidScrollCallback];
    [self.mainTableView reloadData];
    [self.listContainerView reloadData];
}

- (void)preferredProcessListViewDidScroll:(UIScrollView *)scrollView {
    if (self.mainTableView.contentOffset.y < [self.delegate tableHeaderViewHeightInPagingView:self]) {
        //mainTableView的header还没有消失，让listScrollView一直为0
        scrollView.contentOffset = CGPointZero;
        scrollView.showsVerticalScrollIndicator = NO;
    }else {
        //mainTableView的header刚好消失，固定mainTableView的位置，显示listScrollView的滚动条
        self.mainTableView.contentOffset = CGPointMake(0, [self.delegate tableHeaderViewHeightInPagingView:self]);
        scrollView.showsVerticalScrollIndicator = YES;
    }
}

- (void)preferredProcessMainTableViewDidScroll:(UIScrollView *)scrollView {
    if (self.currentScrollingListView != nil && self.currentScrollingListView.contentOffset.y > 0) {
        //mainTableView的header已经滚动不见，开始滚动某一个listView，那么固定mainTableView的contentOffset，让其不动
        self.mainTableView.contentOffset = CGPointMake(0, [self.delegate tableHeaderViewHeightInPagingView:self]);
    }

    if (scrollView.contentOffset.y < [self.delegate tableHeaderViewHeightInPagingView:self]) {
        //mainTableView已经显示了header，listView的contentOffset需要重置
        NSArray *listViews = [self.delegate listViewsInPagingView:self];
        for (UIView <JXPagingViewListViewDelegate>* listView in listViews) {
            [listView listScrollView].contentOffset = CGPointZero;
        }
    }
}

#pragma mark - Private

- (void)configListViewDidScrollCallback {
    NSArray *listViews = [self.delegate listViewsInPagingView:self];
    for (UIView <JXPagingViewListViewDelegate>* listView in listViews) {
        __weak typeof(self)weakSelf = self;
        [listView listViewDidScrollCallback:^(UIScrollView *scrollView) {
            [weakSelf listViewDidScroll:scrollView];
        }];
    }
}

- (void)listViewDidScroll:(UIScrollView *)scrollView {
    self.currentScrollingListView = scrollView;

    [self preferredProcessListViewDidScroll:scrollView];
}

#pragma mark - UITableViewDataSource, UITableViewDelegate

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return 1;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    return self.bounds.size.height - [self.delegate heightForPinSectionHeaderInPagingView:self];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"cell" forIndexPath:indexPath];
    for (UIView *view in cell.contentView.subviews) {
        [view removeFromSuperview];
    }
    self.listContainerView.frame = cell.contentView.bounds;
    [cell.contentView addSubview:self.listContainerView];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForHeaderInSection:(NSInteger)section {
    return [self.delegate heightForPinSectionHeaderInPagingView:self];
}

- (UIView *)tableView:(UITableView *)tableView viewForHeaderInSection:(NSInteger)section {
    return [self.delegate viewForPinSectionHeaderInPagingView:self];
}

- (void)scrollViewDidScroll:(UIScrollView *)scrollView {
    if ([self.delegate respondsToSelector:@selector(mainTableViewDidScroll:)]) {
        [self.delegate mainTableViewDidScroll:scrollView];
    }

    [self preferredProcessMainTableViewDidScroll:scrollView];
}

#pragma mark - JXPagingListContainerViewDelegate

- (NSInteger)numberOfRowsInListContainerView:(JXPagingListContainerView *)listContainerView {
    NSArray *listViews = [self.delegate listViewsInPagingView:self];
    return listViews.count;
}

- (UIView *)listContainerView:(JXPagingListContainerView *)listContainerView listViewInRow:(NSInteger)row {
    NSArray *listViews = [self.delegate listViewsInPagingView:self];
    return listViews[row];
}

@end
