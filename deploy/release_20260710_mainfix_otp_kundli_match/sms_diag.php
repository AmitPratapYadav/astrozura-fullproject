<?php
require __DIR__.'/vendor/autoload.php';
$app=require_once __DIR__.'/bootstrap/app.php';
$app->make(Illuminate\Contracts\Console\Kernel::class)->bootstrap();
$otp='123456';
$text="Dear User, your AstroZura login OTP is {$otp}. Do not share it with anyone. Valid for 10 minutes. Team AstroZura.";
$response=Illuminate\Support\Facades\Http::timeout(12)->get((string) config('services.ultron_sms.base_url'), [
 'user'=>config('services.ultron_sms.user'),
 'password'=>config('services.ultron_sms.password'),
 'senderid'=>config('services.ultron_sms.sender_id'),
 'channel'=>config('services.ultron_sms.channel'),
 'DCS'=>config('services.ultron_sms.dcs'),
 'flashsms'=>config('services.ultron_sms.flashsms'),
 'number'=>'919548046986',
 'text'=>$text,
 'route'=>config('services.ultron_sms.route'),
 'peid'=>config('services.ultron_sms.peid'),
 'DLTTemplateId'=>config('services.ultron_sms.templates.otp'),
]);
echo 'STATUS='.$response->status().PHP_EOL;
echo 'BODY='.substr($response->body(),0,500).PHP_EOL;
