-- Mock Data for IM System
-- Clean up existing data
DELETE FROM im_conversation;
DELETE FROM im_message;
DELETE FROM im_group_member;
DELETE FROM im_group;
DELETE FROM im_friend_request;
DELETE FROM im_friendship;
DELETE FROM im_user;

-- 1. Users
-- 101: Current User (Me)
-- 102: Li Manager
-- 103: Smart Assistant
-- 104: Colleague A
INSERT INTO im_user (user_id, wx_id, avatar_url, region, signature) VALUES 
(101, 'wxid_me', 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=100&h=100&fit=crop', 'CN', 'Work hard, play hard'),
(102, 'wxid_li', 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=100&h=100&fit=crop', 'CN', 'Risk Management Dept'),
(103, 'wxid_bot', 'https://images.unsplash.com/photo-1485827404703-89b55fcc595e?w=100&h=100&fit=crop', 'US', 'AI Assistant'),
(104, 'wxid_colleague', NULL, 'CN', 'Busier than you');

-- 2. Friendships
-- 101 <-> 102
INSERT INTO im_friendship (user_id, friend_id, remark, status, source) VALUES 
(101, 102, 'Li Manager', 0, 1),
(102, 101, 'Xiao Wang', 0, 1);

-- 3. Groups
-- Group 1: Risk Dept Group
INSERT INTO im_group (id, owner_id, name, notice, invite_mode, member_count) VALUES 
(1, 102, 'Risk Dept Group', 'Please submit daily reports by 5 PM', 0, 3);

-- Group Members
INSERT INTO im_group_member (group_id, user_id, role, alias) VALUES 
(1, 102, 2, 'Manager Li'),
(1, 101, 0, 'Wang'),
(1, 104, 0, 'Zhang');

-- 4. Initial Messages
-- 102 -> 101 (Private)
INSERT INTO im_message (conversation_id, sender_id, receiver_id, msg_type, content, send_time) VALUES 
('101_102', 102, 101, 1, 'Please review the audit logs.', NOW());

-- 102 -> Group 1 (Group)
INSERT INTO im_message (conversation_id, sender_id, group_id, msg_type, content, send_time) VALUES 
('G_1', 102, NULL, 1, 'Report submitted.', NOW());

-- Bot Message
INSERT INTO im_message (conversation_id, sender_id, receiver_id, msg_type, content, send_time) VALUES 
('101_103', 103, 101, 1, 'Hello, I am your banking assistant...', NOW());


-- 5. Conversations (Inbox for User 101)
-- Li Manager
INSERT INTO im_conversation (user_id, peer_id, chat_type, last_msg_content, last_msg_time, unread_count) VALUES 
(101, 102, 1, 'Please review the audit logs.', NOW(), 1);

-- Smart Assistant
INSERT INTO im_conversation (user_id, peer_id, chat_type, last_msg_content, last_msg_time, unread_count) VALUES 
(101, 103, 1, 'Hello, I am your banking assistant...', NOW(), 0);

-- Risk Dept Group
INSERT INTO im_conversation (user_id, peer_id, chat_type, last_msg_content, last_msg_time, unread_count) VALUES 
(101, 1, 2, 'Report submitted.', NOW(), 0);
