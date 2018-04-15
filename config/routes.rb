# Plugin's routes
# See: http://guides.rubyonrails.org/routing.html

get 'projects/:project_id/taskboard', :to => 'taskboard#index', :as => :project_taskboard
# get '/taskboard', :to => 'taskboard#index', :as=> :taskboard
post 'projects/:project_id/taskboard/save', :to => 'taskboard#save'
post 'projects/:project_id/taskboard/columns/create', :to => 'taskboard#create_column', :as => :project_taskboard_columns_create
delete 'projects/:project_id/taskboard/columns/:column_id/delete', :to => 'taskboard#delete_column', :as => :project_taskboard_columns_delete
put 'projects/:project_id/taskboard/columns/update', :to => 'taskboard#update_columns', :as => :project_taskboard_columns_update
# PP
put 'projects/:project_id/taskboard/columns/createdefault', :to => 'taskboard#create_defaultcolumns', :as => :project_taskboard_columns_createdefault
