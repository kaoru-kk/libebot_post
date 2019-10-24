class PostsController < ApplicationController
  before_action :set_post, only: [:show, :edit, :update, :destroy]

  require 'line/bot'
  protect_from_forgery :except => [:callback]

  def client
    @client ||= Line::Bot::Client.new { |config|
      config.channel_secret = ENV["LINE_CHANNEL_SECRET"]
      config.channel_token = ENV["LINE_CHANNEL_TOKEN"]
    }
  end

  def callback
    post = Post.new
    dm = params[:events][0][:message][:text]
    post.name = dm
    post.user_id = params[:events][0][:source][:userId]
    p params[:events][0][:source][:userId]
    unless dm == "まぜそば" || dm == "カメラを起動する" || dm == "嫌い" || dm == "好き!"
      post.save
    end
    posts = Post.where(user_id: params[:events][0][:source][:userId])
    array = Array.new(posts.count)
    posts.each_with_index do |f,c|
      array[c] = f.name
    end

    all_post = ""
    array.each_with_index do |f,c|
      all_post += (c + 1).to_s + "." + array[c] + " \n"
    end
    body = request.body.read

    signature = request.env['HTTP_X_LINE_SIGNATURE']
    unless client.validate_signature(body, signature)
      head :bad_request
    end

    events = client.parse_events_from(body)
    like = {type:"text", text: "大好きです"}

    events.each { |event|
      case event
      when Line::Bot::Event::Message
        case event.type
        when Line::Bot::Event::MessageType::Text
          message = {
            type: 'text',
            text: all_post
        }
          if dm == "カメラを起動する"
            client.reply_message(event['replyToken'], camera)
          elsif dm == "アルバムを開く"
            client.reply_message(event['replyToken'], cameraRoll)           
          elsif dm == "好き!"
            client.reply_message(event['replyToken'], like)
          elsif dm == "まぜそば"
            client.reply_message(event['replyToken'], template)
          else
            client.reply_message(event['replyToken'], message)
          end
        end
      end
    }
    head :ok
  end

  def index
    @posts = Post.all
  end

  # GET /posts/1
  # GET /posts/1.json
  def show
  end

  # GET /posts/new
  def new
    @post = Post.new
  end

  # GET /posts/1/edit
  def edit
  end

  # POST /posts
  # POST /posts.json
  def create
    @post = Post.new(post_params)

    respond_to do |format|
      if @post.save
        format.html { redirect_to @post, notice: 'Post was successfully created.' }
        format.json { render :show, status: :created, location: @post }
      else
        format.html { render :new }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # PATCH/PUT /posts/1
  # PATCH/PUT /posts/1.json
  def update
    respond_to do |format|
      if @post.update(post_params)
        format.html { redirect_to @post, notice: 'Post was successfully updated.' }
        format.json { render :show, status: :ok, location: @post }
      else
        format.html { render :edit }
        format.json { render json: @post.errors, status: :unprocessable_entity }
      end
    end
  end

  # DELETE /posts/1
  # DELETE /posts/1.json
  def destroy
    @post.destroy
    respond_to do |format|
      format.html { redirect_to posts_url, notice: 'Post was successfully destroyed.' }
      format.json { head :no_content }
    end
  end

  private
    # Use callbacks to share common setup or constraints between actions.
    def set_post
      @post = Post.find(params[:id])
    end

    # Never trust parameters from the scary internet, only allow the white list through.
    def post_params
      params.require(:post).permit(:name)
    end

    def template
      {
        "type": "template",
        "altText": "this is template",
        "template":{
          "type": "confirm",
          "text": "まぜそばは好きですか？",
          "actions": [
            {
              "type": "message",
              "label": "カメラを起動する",
              "text": "カメラを起動する"
            },
            # {
            #   "type": "uri",
            #   "label": "卒論",
            #   "uri": "http://54.64.39.151/"
            # }
            {
              "type": "message",
              "label": "アルバム",
              "text": "アルバムを開く"
            }
          ]
        }
      }
    end

    def camera
      camera =  {
        "type": "text",
        "text": "↓のカメラボタンを押してね",
        "quickReply": {
          "items": [
            {
              "type": "action",
              "action": {
                "type": "camera",
                "label": "Camera"
              }
            }
          ]
        }
      }
    end

    def cameraRoll
      cameraRoll =  {
        "type": "text",
        "text": "↓のアルバムを押してね",
        "quickReply": {
          "items": [
            {
              "type": "action",
              "action": {
                "type": "cameraRoll",
                "label": "アルバム"
              }
            }
          ]
        }
      }
    end
end
